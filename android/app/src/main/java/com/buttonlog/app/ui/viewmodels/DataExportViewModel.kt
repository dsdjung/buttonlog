package com.buttonlog.app.ui.viewmodels

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.buttonlog.app.data.api.ApiResult
import com.buttonlog.app.data.repository.UserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import java.io.File
import javax.inject.Inject

@HiltViewModel
class DataExportViewModel @Inject constructor(
    private val application: Application,
    private val userRepository: UserRepository
) : AndroidViewModel(application) {

    var selectedFormat by mutableStateOf("json")

    var isExporting by mutableStateOf(false)
        private set

    var errorMessage by mutableStateOf<String?>(null)
        private set

    var successMessage by mutableStateOf<String?>(null)
        private set

    fun exportData(onExportComplete: (File) -> Unit) {
        viewModelScope.launch {
            isExporting = true
            errorMessage = null
            successMessage = null

            when (val result = userRepository.exportData(selectedFormat)) {
                is ApiResult.Success -> {
                    val (data, filename) = result.data

                    // Save to app's cache directory
                    val cacheDir = application.cacheDir
                    val exportFile = File(cacheDir, filename)
                    exportFile.writeBytes(data)

                    successMessage = "Export complete! File ready to share."
                    onExportComplete(exportFile)
                }
                is ApiResult.Error -> {
                    errorMessage = result.message
                }
                is ApiResult.Loading -> {}
            }

            isExporting = false
        }
    }

    fun clearError() {
        errorMessage = null
    }

    fun clearSuccess() {
        successMessage = null
    }
}
