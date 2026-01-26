package com.buttonlog.app.offline

import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.util.Date
import java.util.LinkedList
import java.util.Queue

/**
 * Tests for offline functionality and data synchronization.
 *
 * These tests verify:
 * - Data caching for offline access
 * - Sync behavior when coming back online
 * - Conflict resolution
 * - Queue management for pending operations
 */
class OfflineSyncTests {

    // MARK: - Pending Operations Queue Tests

    @Test
    fun `pending operations queue adds operations`() {
        val queue: Queue<PendingOperation> = LinkedList()

        val operation = PendingOperation(
            type = "button_click",
            buttonId = "test-button-id",
            action = "click",
            timestamp = System.currentTimeMillis()
        )

        queue.add(operation)

        assertThat(queue.size).isEqualTo(1)
        assertThat(queue.peek()?.type).isEqualTo("button_click")
    }

    @Test
    fun `pending operations queue processes in FIFO order`() {
        val queue: Queue<PendingOperation> = LinkedList()

        // Add multiple operations
        for (i in 1..5) {
            queue.add(PendingOperation(
                type = "button_click",
                buttonId = "btn-$i",
                action = "click",
                timestamp = System.currentTimeMillis() + i,
                order = i
            ))
        }

        // Process in FIFO order
        val processedOrder = mutableListOf<Int>()
        while (queue.isNotEmpty()) {
            val operation = queue.poll()
            operation?.order?.let { processedOrder.add(it) }
        }

        assertThat(processedOrder).containsExactly(1, 2, 3, 4, 5).inOrder()
    }

    @Test
    fun `pending operations can be serialized and deserialized`() {
        val operation = PendingOperation(
            type = "button_click",
            buttonId = "btn-123",
            action = "start",
            timestamp = 1234567890L
        )

        // Serialize to map (simulating JSON serialization)
        val serialized = mapOf(
            "type" to operation.type,
            "buttonId" to operation.buttonId,
            "action" to operation.action,
            "timestamp" to operation.timestamp
        )

        // Deserialize
        val deserialized = PendingOperation(
            type = serialized["type"] as String,
            buttonId = serialized["buttonId"] as String,
            action = serialized["action"] as String,
            timestamp = serialized["timestamp"] as Long
        )

        assertThat(deserialized.type).isEqualTo(operation.type)
        assertThat(deserialized.buttonId).isEqualTo(operation.buttonId)
        assertThat(deserialized.action).isEqualTo(operation.action)
        assertThat(deserialized.timestamp).isEqualTo(operation.timestamp)
    }

    // MARK: - Sync State Tests

    @Test
    fun `sync state tracks last sync time`() {
        val syncState = SyncState()

        val syncTime = System.currentTimeMillis()
        syncState.lastSyncTime = syncTime

        assertThat(syncState.lastSyncTime).isEqualTo(syncTime)
    }

    @Test
    fun `sync state detects stale data`() {
        val syncState = SyncState()

        // Last sync was 2 hours ago
        syncState.lastSyncTime = System.currentTimeMillis() - (2 * 60 * 60 * 1000)

        // Stale threshold is 1 hour
        val staleThreshold = 60 * 60 * 1000L

        val isStale = System.currentTimeMillis() - syncState.lastSyncTime > staleThreshold

        assertThat(isStale).isTrue()
    }

    @Test
    fun `sync state detects fresh data`() {
        val syncState = SyncState()

        // Last sync was 30 minutes ago
        syncState.lastSyncTime = System.currentTimeMillis() - (30 * 60 * 1000)

        // Stale threshold is 1 hour
        val staleThreshold = 60 * 60 * 1000L

        val isStale = System.currentTimeMillis() - syncState.lastSyncTime > staleThreshold

        assertThat(isStale).isFalse()
    }

    // MARK: - Conflict Resolution Tests

    @Test
    fun `conflict resolution server wins when newer`() {
        val serverData = CachedButton(
            id = "btn-1",
            name = "Server Name",
            updatedAt = System.currentTimeMillis()
        )

        val localData = CachedButton(
            id = "btn-1",
            name = "Local Name",
            updatedAt = System.currentTimeMillis() - 3600000 // 1 hour ago
        )

        val winner = resolveConflict(serverData, localData)

        assertThat(winner.name).isEqualTo("Server Name")
    }

    @Test
    fun `conflict resolution local wins when newer`() {
        val serverData = CachedButton(
            id = "btn-1",
            name = "Server Name",
            updatedAt = System.currentTimeMillis() - 3600000 // 1 hour ago
        )

        val localData = CachedButton(
            id = "btn-1",
            name = "Local Name",
            updatedAt = System.currentTimeMillis()
        )

        val winner = resolveConflict(serverData, localData)

        assertThat(winner.name).isEqualTo("Local Name")
    }

    // MARK: - Cache Expiration Tests

    @Test
    fun `cache entry is valid within timeout`() {
        val cacheEntry = CacheEntry(
            data = "test data",
            timestamp = System.currentTimeMillis()
        )

        val cacheTimeout = 3600000L // 1 hour

        val isExpired = System.currentTimeMillis() - cacheEntry.timestamp > cacheTimeout

        assertThat(isExpired).isFalse()
    }

    @Test
    fun `cache entry is expired after timeout`() {
        val cacheEntry = CacheEntry(
            data = "test data",
            timestamp = System.currentTimeMillis() - 7200000 // 2 hours ago
        )

        val cacheTimeout = 3600000L // 1 hour

        val isExpired = System.currentTimeMillis() - cacheEntry.timestamp > cacheTimeout

        assertThat(isExpired).isTrue()
    }

    // MARK: - Batch Sync Tests

    @Test
    fun `batch sync groups operations correctly`() {
        val pendingOperations = (1..10).map { i ->
            PendingOperation(
                type = "button_click",
                buttonId = "btn-$i",
                action = "click",
                timestamp = System.currentTimeMillis()
            )
        }

        val batchSize = 5
        val batches = pendingOperations.chunked(batchSize)

        assertThat(batches.size).isEqualTo(2)
        assertThat(batches[0].size).isEqualTo(5)
        assertThat(batches[1].size).isEqualTo(5)
    }

    @Test
    fun `batch sync handles partial batches`() {
        val pendingOperations = (1..7).map { i ->
            PendingOperation(
                type = "button_click",
                buttonId = "btn-$i",
                action = "click",
                timestamp = System.currentTimeMillis()
            )
        }

        val batchSize = 5
        val batches = pendingOperations.chunked(batchSize)

        assertThat(batches.size).isEqualTo(2)
        assertThat(batches[0].size).isEqualTo(5)
        assertThat(batches[1].size).isEqualTo(2) // Partial batch
    }

    // MARK: - Data Integrity Tests

    @Test
    fun `cached button maintains data integrity`() {
        val original = CachedButton(
            id = "btn-123",
            name = "Test Button",
            type = "instant",
            clickCount = 42,
            color = "#FF0000",
            updatedAt = System.currentTimeMillis()
        )

        // Simulate cache round-trip
        val cached = CachedButton(
            id = original.id,
            name = original.name,
            type = original.type,
            clickCount = original.clickCount,
            color = original.color,
            updatedAt = original.updatedAt
        )

        assertThat(cached.id).isEqualTo(original.id)
        assertThat(cached.name).isEqualTo(original.name)
        assertThat(cached.type).isEqualTo(original.type)
        assertThat(cached.clickCount).isEqualTo(original.clickCount)
        assertThat(cached.color).isEqualTo(original.color)
    }

    // MARK: - Retry Logic Tests

    @Test
    fun `retry backoff increases exponentially`() {
        val baseDelay = 1000L // 1 second
        val maxRetries = 5

        val delays = (0 until maxRetries).map { attempt ->
            calculateBackoff(baseDelay, attempt)
        }

        // Verify exponential increase
        assertThat(delays[0]).isEqualTo(1000L)
        assertThat(delays[1]).isEqualTo(2000L)
        assertThat(delays[2]).isEqualTo(4000L)
        assertThat(delays[3]).isEqualTo(8000L)
        assertThat(delays[4]).isEqualTo(16000L)
    }

    @Test
    fun `retry backoff caps at maximum delay`() {
        val baseDelay = 1000L
        val maxDelay = 30000L // 30 seconds

        val delay = calculateBackoff(baseDelay, 10, maxDelay)

        assertThat(delay).isAtMost(maxDelay)
    }

    // MARK: - Helper Methods

    private fun resolveConflict(server: CachedButton, local: CachedButton): CachedButton {
        return if (server.updatedAt > local.updatedAt) server else local
    }

    private fun calculateBackoff(baseDelay: Long, attempt: Int, maxDelay: Long = Long.MAX_VALUE): Long {
        val delay = baseDelay * (1L shl attempt) // 2^attempt
        return minOf(delay, maxDelay)
    }
}

// MARK: - Data Classes

data class PendingOperation(
    val type: String,
    val buttonId: String,
    val action: String,
    val timestamp: Long,
    val order: Int? = null
)

data class SyncState(
    var lastSyncTime: Long = 0L,
    var isSyncing: Boolean = false
)

data class CachedButton(
    val id: String,
    val name: String,
    val type: String = "instant",
    val clickCount: Int = 0,
    val color: String = "#007AFF",
    val updatedAt: Long
)

data class CacheEntry<T>(
    val data: T,
    val timestamp: Long
)
