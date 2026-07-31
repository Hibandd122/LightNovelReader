import XCTest
@testable import LightNovelReader

final class OfflineSyncUseCaseTests: XCTestCase {
    
    var useCase: SyncOfflineDataUseCaseProtocol!
    
    override func setUp() {
        super.setUp()
        // Mocking SyncManager
        let mockNetwork = MockNetworkService()
        let syncManager = SyncManager(networkService: mockNetwork)
        useCase = SyncOfflineDataUseCase(syncManager: syncManager)
    }
    
    override func tearDown() {
        useCase = nil
        super.tearDown()
    }
    
    func testConflictResolution_WhenRevisionsMatch_ShouldReturnTrue() async {
        let result = await useCase.resolveConflict(localRevision: "v123", remoteRevision: "v123")
        XCTAssertTrue(result)
    }
    
    func testConflictResolution_WhenRemoteIsNewer_ShouldReturnFalse() async {
        let result = await useCase.resolveConflict(localRevision: "v123", remoteRevision: "v124")
        XCTAssertFalse(result)
    }
}

class MockNetworkService: NetworkService {
    func request<T>(endpoint: Endpoint) async throws -> T where T : Decodable {
        fatalError("Mock not implemented")
    }
    
    func requestRaw(endpoint: Endpoint) async throws -> Data {
        return Data()
    }
}
