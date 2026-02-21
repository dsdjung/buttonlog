package com.buttonlog.app.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.model.ActivityCursor
import com.buttonlog.app.data.model.FeedActivity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ActivityFeedViewModel @Inject constructor(
    private val apiService: APIService
) : ViewModel() {

    private val _uiState = MutableStateFlow(ActivityFeedUiState())
    val uiState: StateFlow<ActivityFeedUiState> = _uiState.asStateFlow()

    fun loadActivityFeed() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                val response = apiService.getActivityFeed(limit = 20)
                if (response.success) {
                    _uiState.update {
                        it.copy(
                            activities = response.data,
                            hasMore = response.meta?.hasMore ?: false,
                            nextCursor = response.meta?.nextCursor,
                            isLoading = false
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            error = response.error?.message ?: "Failed to load activity",
                            isLoading = false
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        error = e.message ?: "Unknown error",
                        isLoading = false
                    )
                }
            }
        }
    }

    fun loadMore() {
        val state = _uiState.value
        if (!state.hasMore || state.isLoadingMore || state.nextCursor == null) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingMore = true) }

            try {
                val cursor = state.nextCursor
                val response = apiService.getActivityFeed(
                    limit = 20,
                    cursor = cursor.clickedAt,
                    cursorId = cursor.id
                )

                if (response.success) {
                    _uiState.update {
                        it.copy(
                            activities = it.activities + response.data,
                            hasMore = response.meta?.hasMore ?: false,
                            nextCursor = response.meta?.nextCursor,
                            isLoadingMore = false
                        )
                    }
                } else {
                    _uiState.update { it.copy(isLoadingMore = false) }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoadingMore = false) }
            }
        }
    }

    fun refresh() {
        loadActivityFeed()
    }
}

data class ActivityFeedUiState(
    val activities: List<FeedActivity> = emptyList(),
    val hasMore: Boolean = false,
    val nextCursor: ActivityCursor? = null,
    val isLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val error: String? = null
)
