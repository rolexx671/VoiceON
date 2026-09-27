import AppKit
import AVFoundation
import ApplicationServices
import Foundation

struct Permissions {
    static func ensureMicrophone() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("Микрофон: доступ разрешён")
        case .notDetermined:
            print("Микрофон: запрос доступа…")
            let semaphore = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print("Микрофон: \(granted ? "доступ разрешён" : "доступ запрещён")")
                semaphore.signal()
            }
            semaphore.wait()
        default:
            print("Микрофон: доступ запрещён. Разрешите его в Системных настройках → Конфиденциальность и безопасность → Микрофон")
        }
    }

    static func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func shouldResetAccessibility(afterUpgrade: Bool, isTrusted: Bool) -> Bool {
        afterUpgrade && !isTrusted
    }

    static func resetAccessibility() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", "Accessibility", Bundle.main.bundleIdentifier ?? "com.voiceon.app"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    static func didUpgrade() -> Bool {
        didUpgrade(versionFile: versionFile, currentVersion: OpenWispr.version)
    }

    static func didUpgrade(versionFile: URL, currentVersion: String) -> Bool {
        let raw = (try? String(contentsOf: versionFile, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let previous = raw.isEmpty ? nil : raw
        return previous != nil && previous != currentVersion
    }

    static func recordCurrentVersion() {
        do {
            try recordCurrentVersion(to: versionFile, version: OpenWispr.version)
        } catch {
            print("Универсальный доступ: не удалось сохранить текущую версию: \(error.localizedDescription)")
        }
    }

    static func recordCurrentVersion(to versionFile: URL, version: String) throws {
        try FileManager.default.createDirectory(
            at: versionFile.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try version.write(to: versionFile, atomically: true, encoding: .utf8)
    }

    private static var versionFile: URL {
        Config.configDir.appendingPathComponent(".last-version")
    }

    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
