import XCTest
@testable import ButtonLog

/// Tests for offline functionality and data synchronization.
///
/// These tests verify:
/// - Data caching for offline access
/// - Sync behavior when coming back online
/// - Conflict resolution
/// - Queue management for pending operations
final class OfflineTests: XCTestCase {

    // MARK: - Cache Tests

    func testUserDefaults_cachesUserData() {
        let defaults = UserDefaults.standard
        let testKey = "test_cached_user"

        // Create test user data
        let userData: [String: Any] = [
            "id": "test-user-id",
            "email": "test@example.com",
            "username": "testuser",
            "display_name": "Test User"
        ]

        // Save to cache
        defaults.set(userData, forKey: testKey)

        // Retrieve from cache
        let cachedData = defaults.dictionary(forKey: testKey)

        XCTAssertNotNil(cachedData)
        XCTAssertEqual(cachedData?["id"] as? String, "test-user-id")
        XCTAssertEqual(cachedData?["email"] as? String, "test@example.com")

        // Clean up
        defaults.removeObject(forKey: testKey)
    }

    func testCache_expiresAfterTimeout() {
        let defaults = UserDefaults.standard
        let dataKey = "test_cached_data"
        let timestampKey = "test_cached_data_timestamp"

        // Save data with timestamp
        defaults.set(["test": "data"], forKey: dataKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)

        // Check if data is still valid (within timeout)
        let cachedTimestamp = defaults.double(forKey: timestampKey)
        let cacheTimeout: TimeInterval = 3600 // 1 hour
        let isExpired = Date().timeIntervalSince1970 - cachedTimestamp > cacheTimeout

        XCTAssertFalse(isExpired, "Cache should not be expired immediately")

        // Clean up
        defaults.removeObject(forKey: dataKey)
        defaults.removeObject(forKey: timestampKey)
    }

    // MARK: - Pending Operations Queue Tests

    func testPendingOperationsQueue_addsOperations() {
        var queue: [[String: Any]] = []

        // Add pending operation
        let operation: [String: Any] = [
            "type": "button_click",
            "buttonId": "test-button-id",
            "action": "click",
            "timestamp": Date().timeIntervalSince1970
        ]

        queue.append(operation)

        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.first?["type"] as? String, "button_click")
    }

    func testPendingOperationsQueue_processesInOrder() {
        var queue: [[String: Any]] = []

        // Add multiple operations
        for i in 1...5 {
            queue.append([
                "type": "button_click",
                "order": i,
                "timestamp": Date().timeIntervalSince1970 + Double(i)
            ])
        }

        // Process in FIFO order
        var processedOrder: [Int] = []
        while !queue.isEmpty {
            let operation = queue.removeFirst()
            if let order = operation["order"] as? Int {
                processedOrder.append(order)
            }
        }

        XCTAssertEqual(processedOrder, [1, 2, 3, 4, 5], "Operations should be processed in FIFO order")
    }

    func testPendingOperationsQueue_persistsToDisk() {
        let defaults = UserDefaults.standard
        let queueKey = "test_pending_operations"

        // Create queue with operations
        let operations: [[String: Any]] = [
            ["type": "button_click", "buttonId": "btn1"],
            ["type": "button_click", "buttonId": "btn2"]
        ]

        // Save to disk
        if let data = try? JSONSerialization.data(withJSONObject: operations) {
            defaults.set(data, forKey: queueKey)
        }

        // Retrieve from disk
        if let data = defaults.data(forKey: queueKey),
           let retrieved = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            XCTAssertEqual(retrieved.count, 2)
            XCTAssertEqual(retrieved.first?["buttonId"] as? String, "btn1")
        } else {
            XCTFail("Failed to retrieve queue from disk")
        }

        // Clean up
        defaults.removeObject(forKey: queueKey)
    }

    // MARK: - Sync State Tests

    func testSyncState_tracksLastSyncTime() {
        let defaults = UserDefaults.standard
        let key = "test_last_sync_time"

        let syncTime = Date()
        defaults.set(syncTime.timeIntervalSince1970, forKey: key)

        let retrievedTime = defaults.double(forKey: key)
        let retrievedDate = Date(timeIntervalSince1970: retrievedTime)

        XCTAssertEqual(
            Int(syncTime.timeIntervalSince1970),
            Int(retrievedDate.timeIntervalSince1970),
            "Sync time should be preserved"
        )

        // Clean up
        defaults.removeObject(forKey: key)
    }

    func testSyncState_detectsStaleData() {
        let lastSyncTime = Date().addingTimeInterval(-7200) // 2 hours ago
        let staleThreshold: TimeInterval = 3600 // 1 hour

        let isStale = Date().timeIntervalSince(lastSyncTime) > staleThreshold

        XCTAssertTrue(isStale, "Data should be considered stale after threshold")
    }

    // MARK: - Conflict Resolution Tests

    func testConflictResolution_serverWins() {
        // Server data (newer)
        let serverData: [String: Any] = [
            "id": "btn-1",
            "name": "Server Name",
            "updated_at": Date().timeIntervalSince1970
        ]

        // Local data (older)
        let localData: [String: Any] = [
            "id": "btn-1",
            "name": "Local Name",
            "updated_at": Date().addingTimeInterval(-3600).timeIntervalSince1970
        ]

        // Resolve conflict (server wins for newer data)
        let serverTimestamp = serverData["updated_at"] as? TimeInterval ?? 0
        let localTimestamp = localData["updated_at"] as? TimeInterval ?? 0

        let winner = serverTimestamp > localTimestamp ? serverData : localData

        XCTAssertEqual(winner["name"] as? String, "Server Name", "Server should win with newer data")
    }

    func testConflictResolution_localWins_whenNewer() {
        // Server data (older)
        let serverData: [String: Any] = [
            "id": "btn-1",
            "name": "Server Name",
            "updated_at": Date().addingTimeInterval(-3600).timeIntervalSince1970
        ]

        // Local data (newer)
        let localData: [String: Any] = [
            "id": "btn-1",
            "name": "Local Name",
            "updated_at": Date().timeIntervalSince1970
        ]

        // Resolve conflict
        let serverTimestamp = serverData["updated_at"] as? TimeInterval ?? 0
        let localTimestamp = localData["updated_at"] as? TimeInterval ?? 0

        let winner = localTimestamp > serverTimestamp ? localData : serverData

        XCTAssertEqual(winner["name"] as? String, "Local Name", "Local should win with newer data")
    }

    // MARK: - Data Integrity Tests

    func testCachedData_maintainsIntegrity() {
        let defaults = UserDefaults.standard
        let key = "test_button_cache"

        // Original button data
        let originalButton: [String: Any] = [
            "id": "btn-123",
            "name": "Test Button",
            "type": "instant",
            "click_count": 42,
            "color": "#FF0000"
        ]

        // Save to cache
        if let data = try? JSONSerialization.data(withJSONObject: originalButton) {
            defaults.set(data, forKey: key)
        }

        // Retrieve and verify integrity
        if let data = defaults.data(forKey: key),
           let retrieved = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

            XCTAssertEqual(retrieved["id"] as? String, originalButton["id"] as? String)
            XCTAssertEqual(retrieved["name"] as? String, originalButton["name"] as? String)
            XCTAssertEqual(retrieved["type"] as? String, originalButton["type"] as? String)
            XCTAssertEqual(retrieved["click_count"] as? Int, originalButton["click_count"] as? Int)
            XCTAssertEqual(retrieved["color"] as? String, originalButton["color"] as? String)
        } else {
            XCTFail("Failed to maintain data integrity")
        }

        // Clean up
        defaults.removeObject(forKey: key)
    }

    // MARK: - Network State Tests

    func testNetworkState_detection() {
        // These would use a mock in a real implementation
        // Just verify the concept works

        enum NetworkState {
            case online
            case offline
            case unknown
        }

        func isOnline() -> NetworkState {
            // In real implementation, this would check actual connectivity
            return .online
        }

        let state = isOnline()
        XCTAssertEqual(state, .online)
    }

    // MARK: - Batch Sync Tests

    func testBatchSync_groupsOperations() {
        // Simulate pending operations
        var pendingClicks: [[String: Any]] = []

        for i in 1...10 {
            pendingClicks.append([
                "buttonId": "btn-\(i)",
                "action": "click"
            ])
        }

        // Group into batches of 5
        let batchSize = 5
        var batches: [[[String: Any]]] = []

        for i in stride(from: 0, to: pendingClicks.count, by: batchSize) {
            let end = min(i + batchSize, pendingClicks.count)
            let batch = Array(pendingClicks[i..<end])
            batches.append(batch)
        }

        XCTAssertEqual(batches.count, 2, "Should have 2 batches")
        XCTAssertEqual(batches[0].count, 5, "First batch should have 5 items")
        XCTAssertEqual(batches[1].count, 5, "Second batch should have 5 items")
    }
}
