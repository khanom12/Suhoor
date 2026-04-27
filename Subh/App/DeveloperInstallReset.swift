import Foundation

enum DeveloperInstallReset {
    static let fingerprintKey = "Subh.DebugInstallFingerprint"

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
        afterReset: () -> Void = {}
    ) -> Bool {
        guard let bundleIdentifier else { return false }
        guard defaults.string(forKey: fingerprintKey) != fingerprint else { return false }

        defaults.removePersistentDomain(forName: bundleIdentifier)
        defaults.set(fingerprint, forKey: fingerprintKey)
        afterReset()
        return true
    }
}
