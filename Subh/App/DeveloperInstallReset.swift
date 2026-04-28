import Foundation

enum DeveloperInstallReset {
    static let fingerprintKey = "Subh.DebugInstallFingerprint"
    static let modeDefaultsKey = "Subh.DebugInstallResetMode"
    static let modeEnvironmentKey = "SUBH_DEBUG_INSTALL_RESET_MODE"

    enum Mode: String {
        case disabled
        case onInstallChange
    }

    static func currentFingerprint(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let executableURL = bundle.executableURL
        let attributes = executableURL.flatMap { try? FileManager.default.attributesOfItem(atPath: $0.path) }
        let modifiedAt = (attributes?[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0
        let fileSize = attributes?[.size] as? NSNumber

        return [
            version,
            build,
            executableURL?.lastPathComponent ?? "unknown-executable",
            String(format: "%.0f", modifiedAt),
            fileSize?.stringValue ?? "unknown-size",
        ].joined(separator: "|")
    }

    @discardableResult
    static func resetIfNeeded(
        defaults: UserDefaults = .standard,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        fingerprint: String = currentFingerprint(),
        mode: Mode? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        afterReset: () -> Void = {}
    ) -> Bool {
        let resolvedMode = mode ?? configuredMode(defaults: defaults, environment: environment)
        guard resolvedMode == .onInstallChange else { return false }
        guard let bundleIdentifier else { return false }
        guard defaults.string(forKey: fingerprintKey) != fingerprint else { return false }

        defaults.removePersistentDomain(forName: bundleIdentifier)
        defaults.set(fingerprint, forKey: fingerprintKey)
        afterReset()
        return true
    }

    static func configuredMode(
        defaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Mode {
        if let rawEnvironmentValue = environment[modeEnvironmentKey],
           let environmentMode = parseMode(rawEnvironmentValue) {
            return environmentMode
        }

        if let rawDefaultsValue = defaults.string(forKey: modeDefaultsKey),
           let defaultsMode = parseMode(rawDefaultsValue) {
            return defaultsMode
        }

        return .disabled
    }

    private static func parseMode(_ rawValue: String) -> Mode? {
        switch rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "disabled":
            return .disabled
        case "oninstallchange", "on-install-change", "on_install_change":
            return .onInstallChange
        default:
            return nil
        }
    }
}
