import AppKit

/// Quits and reopens the app, e.g. so a newly granted Screen Recording
/// permission takes effect.
enum AppRelauncher {
    static func relaunch() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        // The bundle path is passed as $0 rather than interpolated, so no
        // quoting is needed. The delay lets this instance exit first.
        process.arguments = ["-c", "sleep 0.5; /usr/bin/open \"$0\"", Bundle.main.bundlePath]
        do {
            try process.run()
            NSApp.terminate(nil)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}
