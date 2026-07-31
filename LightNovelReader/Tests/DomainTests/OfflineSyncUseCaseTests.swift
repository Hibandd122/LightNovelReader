import XCTest
import SwiftData
@testable import LightNovelReader

final class OfflineSyncUseCaseTests: XCTestCase {
    @MainActor
    func testConflictResolutionWhenRevisionsMatch() async {
        let useCase = SyncOfflineDataUseCase(syncManager: SyncManager(repository: StubGoogleDocsRepository()))
        let result = await useCase.resolveConflict(localRevision: "v123", remoteRevision: "v123")
        XCTAssertTrue(result)
    }

    @MainActor
    func testConflictResolutionWhenRemoteIsNewer() async {
        let useCase = SyncOfflineDataUseCase(syncManager: SyncManager(repository: StubGoogleDocsRepository()))
        let result = await useCase.resolveConflict(localRevision: "v123", remoteRevision: "v124")
        XCTAssertFalse(result)
    }
}

@MainActor
private struct StubGoogleDocsRepository: GoogleDocsRepositoryProtocol {
    func fetchAndSaveDocument(id: String, context: ModelContext) async throws {}
    func pushLocalChanges(for novel: Novel, context: ModelContext) async throws {}
}
