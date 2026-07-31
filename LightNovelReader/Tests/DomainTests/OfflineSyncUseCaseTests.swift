import XCTest
import SwiftData
@testable import LightNovelReader

@MainActor
final class OfflineSyncUseCaseTests: XCTestCase {
    private var useCase: SyncOfflineDataUseCase?

    override func setUp() {
        super.setUp()
        let syncManager = SyncManager(repository: StubGoogleDocsRepository())
        useCase = SyncOfflineDataUseCase(syncManager: syncManager)
    }

    override func tearDown() {
        useCase = nil
        super.tearDown()
    }

    func testConflictResolutionWhenRevisionsMatch() async {
        guard let useCase else { return XCTFail("Use case was not initialized") }
        let result = await useCase.resolveConflict(localRevision: "v123", remoteRevision: "v123")
        XCTAssertTrue(result)
    }

    func testConflictResolutionWhenRemoteIsNewer() async {
        guard let useCase else { return XCTFail("Use case was not initialized") }
        let result = await useCase.resolveConflict(localRevision: "v123", remoteRevision: "v124")
        XCTAssertFalse(result)
    }
}

@MainActor
private struct StubGoogleDocsRepository: GoogleDocsRepositoryProtocol {
    func fetchAndSaveDocument(id: String, context: ModelContext) async throws {}
    func pushLocalChanges(for novel: Novel, context: ModelContext) async throws {}
}
