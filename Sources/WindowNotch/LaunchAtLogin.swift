import AppKit
import Observation
import ServiceManagement

/// Registers the app as a login item via `SMAppService`.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var isEnabled = false

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
        if SMAppService.mainApp.status == .requiresApproval {
            // The user has to allow it in System Settings > Login Items.
            SMAppService.openSystemSettingsLoginItems()
        }
        refresh()
    }
}
