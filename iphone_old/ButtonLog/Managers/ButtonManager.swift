import Foundation
import Combine

@MainActor
class ButtonManager: ObservableObject {
    @Published var buttons: [Button] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up API service auth token when user logs in
        NotificationCenter.default.addObserver(
            forName: .userDidLogin,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let token = notification.userInfo?["token"] as? String {
                self?.apiService.setAuthToken(token)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.apiService.clearAuthToken()
            self?.buttons = []
        }
    }
    
    // MARK: - Button Operations
    
    func fetchButtons() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedButtons = try await withCheckedThrowingContinuation { continuation in
                apiService.getButtons()
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { buttons in
                            continuation.resume(returning: buttons)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            buttons = fetchedButtons
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createButton(_ buttonData: ButtonFormData) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newButton = try await withCheckedThrowingContinuation { continuation in
                apiService.createButton(buttonData)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { button in
                            continuation.resume(returning: button)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            buttons.append(newButton)
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func updateButton(_ button: Button) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedButton = try await withCheckedThrowingContinuation { continuation in
                apiService.updateButton(button)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { button in
                            continuation.resume(returning: button)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            if let index = buttons.firstIndex(where: { $0.id == button.id }) {
                buttons[index] = updatedButton
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func deleteButton(_ buttonId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                apiService.deleteButton(buttonId)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { _ in
                            continuation.resume()
                        }
                    )
                    .store(in: &cancellables)
            }
            
            buttons.removeAll { $0.id == buttonId }
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func clickButton(_ buttonId: String) async {
        do {
            let click = try await withCheckedThrowingContinuation { continuation in
                apiService.clickButton(buttonId)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { click in
                            continuation.resume(returning: click)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            // Update button state if it's a state button
            if let index = buttons.firstIndex(where: { $0.id == buttonId }) {
                var updatedButton = buttons[index]
                if updatedButton.type == .state {
                    // Toggle state
                    let newState: ButtonState = updatedButton.currentState == .idle ? .active : .idle
                    updatedButton = Button(
                        id: updatedButton.id,
                        name: updatedButton.name,
                        description: updatedButton.description,
                        type: updatedButton.type,
                        icon: updatedButton.icon,
                        color: updatedButton.color,
                        isActive: updatedButton.isActive,
                        currentState: newState,
                        stateChangedAt: Date(),
                        notificationsEnabled: updatedButton.notificationsEnabled,
                        autoStopEnabled: updatedButton.autoStopEnabled,
                        calendarSyncEnabled: updatedButton.calendarSyncEnabled,
                        userId: updatedButton.userId,
                        createdAt: updatedButton.createdAt,
                        updatedAt: Date()
                    )
                    buttons[index] = updatedButton
                }
            }
            
            // Show success feedback
            await showClickFeedback()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helper Methods
    
    private func showClickFeedback() async {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Could also show a temporary success message or animation
    }
    
    func getButton(by id: String) -> Button? {
        return buttons.first { $0.id == id }
    }
    
    func getButtonsByType(_ type: ButtonType) -> [Button] {
        return buttons.filter { $0.type == type }
    }
    
    func getActiveButtons() -> [Button] {
        return buttons.filter { $0.isActive }
    }
    
    func searchButtons(query: String) -> [Button] {
        if query.isEmpty {
            return buttons
        }
        
        return buttons.filter { button in
            button.name.localizedCaseInsensitiveContains(query) ||
            (button.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
}
