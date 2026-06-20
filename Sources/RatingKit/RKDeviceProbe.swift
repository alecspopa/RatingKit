import Foundation

struct RKDeviceData: Codable {
    let appVersion: String
    let appBuild: String
    let bundleId: String
    let deviceModel: String
    let locale: String
    let region: String
    let preferredLanguages: [String]
    let timezone: String
    let physicalMemoryMb: Int
    let lowPowerMode: Bool
    let thermalState: String
}

/// Gathers passive device with NO permission prompts.
///
/// Everything here is a system-framework property (no consent needed)
///
/// Notably *not* gathered: IDFA (would need ATT prompt), location, contacts,
/// device name (often contains the user's real name, privacy hazard).
enum RKDeviceProbe {
    /// `@MainActor` because we read UIScreen / UIApplication / the foreground
    /// tracker, all of which are MainActor-isolated. Marking this here means
    /// the SDK works in host apps regardless of their default-actor-isolation
    /// build setting.
    @MainActor
    static func snapshot() -> RKDeviceData {
        let bundle = Bundle.main

        var out: RKDeviceData = .init(
            appVersion: (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "",
            appBuild: (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "",
            bundleId: bundle.bundleIdentifier ?? "",
            deviceModel: deviceModelIdentifier(),
            locale: Locale.current.identifier,
            region: Locale.current.region?.identifier ?? "",
            preferredLanguages: Locale.preferredLanguages.prefix(3).map{String($0)},
            timezone: TimeZone.current.identifier,
            physicalMemoryMb: Int(ProcessInfo.processInfo.physicalMemory / 1_048_576),
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermalState: thermalStateString()
        )

        return out
    }

    // MARK: Helpers

    /// Hardware identifier like "iPhone15,3" via uname(2) — Apple's official
    /// public way to identify the model class without permission.
    private static func deviceModelIdentifier() -> String {
        var info = utsname()
        uname(&info)
        let id = withUnsafePointer(to: &info.machine) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
        return id
    }

    private static func freeDiskBytes() -> Int64? {
        guard let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            return nil
        }
        guard let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]) else {
            return nil
        }
        return values.volumeAvailableCapacityForImportantUsage
    }

    private static func thermalStateString() -> String {
        switch ProcessInfo.processInfo.thermalState {
            case .nominal:  return "nominal"
            case .fair:     return "fair"
            case .serious:  return "serious"
            case .critical: return "critical"
            @unknown default: return "unknown"
        }
    }
}
