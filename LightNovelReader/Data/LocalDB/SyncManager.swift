import Foundation
import Combine
import Network
import SwiftData
import OSLog
@preconcurrency import BackgroundTasks

@MainActor
public final class SyncManager: ObservableObject {
    private static let backgroundTaskIdentifier = "com.lightnovelreader.sync.refresh"
    private let repository: GoogleDocsRepositoryProtocol
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.lightnovel.syncmonitor")
    private let logger = Logger(subsystem: "com.lightnovelreader", category: "sync")
    private var modelContext: ModelContext?
    private var syncTask: Task<Void, Never>?

    public private(set) var isOnline = false
    public private(set) var isSyncing = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var conflictDocumentID: String?

    public init(repository: GoogleDocsRepositoryProtocol) {
        self.repository = repository
        registerBackgroundTask()
        startMonitoring()
    }

    public func configure(context: ModelContext) {
        modelContext = context
        scheduleBackgroundRefresh()
        if isOnline { triggerSync() }
    }

    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.backgroundTaskIdentifier, using: nil) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor [weak self] in
                await self?.performBackgroundRefresh(refreshTask)
            }
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            logger.debug("Could not schedule background sync: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func performBackgroundRefresh(_ task: BGAppRefreshTask) async {
        task.expirationHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.syncTask?.cancel()
            }
        }
        triggerSync()
        if let syncTask { await syncTask.value }
        task.setTaskCompleted(success: !isSyncing)
        scheduleBackgroundRefresh()
    }

    public func triggerSync() {
        guard !isSyncing, let context = modelContext, isOnline else { return }
        isSyncing = true
        syncTask = Task { [weak self] in
            await self?.processPendingJobs(context: context)
        }
    }

    public func clearConflict() {
        conflictDocumentID = nil
        lastError = nil
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isOnline = online
                if online { self.triggerSync() }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func processPendingJobs(context: ModelContext) async {
        defer {
            isSyncing = false
            syncTask = nil
        }

        do {
            let descriptor = FetchDescriptor<SyncJob>(
                predicate: #Predicate { $0.status == 0 || $0.status == 2 },
                sortBy: [SortDescriptor(\SyncJob.createdAt)]
            )
            let now = Date()
            let jobs = try context.fetch(descriptor).filter { ($0.nextAttemptAt ?? .distantPast) <= now }
            for job in jobs {
                guard isOnline else { return }
                let documentID = job.documentId
                guard let novel = try context.fetch(FetchDescriptor<Novel>(predicate: #Predicate { $0.id == documentID })).first else {
                    job.status = 2
                    continue
                }
                job.status = 1
                try context.save()
                do {
                    try await repository.pushLocalChanges(for: novel, context: context)
                    context.delete(job)
                    novel.syncStatus = 0
                    lastError = nil
                } catch let error where isRevisionConflict(error) {
                    job.status = 3
                    job.nextAttemptAt = nil
                    novel.syncStatus = 2
                    conflictDocumentID = novel.id
                    lastError = error.localizedDescription
                } catch {
                    job.status = 2
                    job.retryCount += 1
                    let delay = min(pow(2.0, Double(job.retryCount + 1)), 3600)
                    job.nextAttemptAt = Date().addingTimeInterval(delay)
                    novel.syncStatus = 1
                    lastError = error.localizedDescription
                    logger.error("Sync failed for job \(job.id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    Task { [weak self] in
                        try? await Task.sleep(for: .seconds(delay))
                        guard !Task.isCancelled else { return }
                        await MainActor.run { self?.triggerSync() }
                    }
                }
                try context.save()
            }
        } catch {
            logger.error("Could not process sync queue: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func isRevisionConflict(_ error: Error) -> Bool {
        if case NetworkError.revisionConflict = error { return true }
        return false
    }
}
