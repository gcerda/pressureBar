import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var statusDescription = "Off"
    @Published private(set) var approvalRequired = false
    @Published private(set) var errorMessage: String?

    func refreshStatus() {
        errorMessage = nil

        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
            approvalRequired = false
            statusDescription = "On"
        case .requiresApproval:
            isEnabled = true
            approvalRequired = true
            statusDescription = "Pending approval"
        case .notRegistered:
            isEnabled = false
            approvalRequired = false
            statusDescription = "Off"
        case .notFound:
            isEnabled = false
            approvalRequired = false
            statusDescription = "Unavailable"
            errorMessage = "macOS could not find the login item registration for PressureBar."
        @unknown default:
            isEnabled = false
            approvalRequired = false
            statusDescription = "Unknown"
            errorMessage = "Launch at login returned an unknown state."
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            refreshStatus()
        } catch {
            refreshStatus()
            errorMessage = error.localizedDescription
        }
    }
}
