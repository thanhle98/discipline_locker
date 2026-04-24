import Foundation

enum ShutdownDaemonManager {
    nonisolated static let plistPath = "/Library/LaunchDaemons/socfam.discipline-locker.shutdown.plist"
    nonisolated static let label = "socfam.discipline-locker.shutdown"

    enum DaemonError: LocalizedError {
        case installFailed(String)
        case userCancelled

        var errorDescription: String? {
            switch self {
            case .installFailed(let msg): "Failed to install shutdown daemon: \(msg)"
            case .userCancelled: "Installation cancelled by user."
            }
        }
    }

    nonisolated static func install(schedules: [DaySchedule]) throws {
        let enabled = schedules.filter(\.isEnabled)
        guard !enabled.isEmpty else {
            try uninstall()
            return
        }

        let plistContent = buildPlist(from: enabled)
        guard let plistData = plistContent.data(using: .utf8) else {
            throw DaemonError.installFailed("Failed to encode plist content")
        }
        let base64 = plistData.base64EncodedString()

        let shellCmd = "launchctl bootout system/\(label) 2>/dev/null; echo \(base64) | base64 -d > \(plistPath); chmod 644 \(plistPath); chown root:wheel \(plistPath); launchctl bootstrap system \(plistPath)"
        let script = "do shell script \"\(shellCmd)\" with administrator privileges"
        try runOsascript(script)
    }

    nonisolated static func uninstall() throws {
        let shellCmd = "launchctl bootout system/\(label) 2>/dev/null; rm -f \(plistPath)"
        let script = "do shell script \"\(shellCmd)\" with administrator privileges"
        try runOsascript(script)
    }

    nonisolated static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    nonisolated private static func runOsascript(_ appleScript: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorStr = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            if errorStr.contains("User canceled") || errorStr.contains("-128") {
                throw DaemonError.userCancelled
            }
            throw DaemonError.installFailed(errorStr)
        }
    }

    // NOTE: Using /usr/bin/logger for safety during development.
    // Change to /sbin/shutdown -h now for production use.
    nonisolated private static func buildPlist(from schedules: [DaySchedule]) -> String {
        var intervals = ""
        for s in schedules {
            intervals += """
                        <dict>
                            <key>Weekday</key>
                            <integer>\(s.day.rawValue)</integer>
                            <key>Hour</key>
                            <integer>\(s.hour)</integer>
                            <key>Minute</key>
                            <integer>\(s.minute)</integer>
                        </dict>\n
            """
        }

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/sbin/shutdown</string>
                <string>-h</string>
                <string>now</string>
            </array>
            <key>StartCalendarInterval</key>
            <array>
        \(intervals)    </array>
        </dict>
        </plist>
        """
    }
}
