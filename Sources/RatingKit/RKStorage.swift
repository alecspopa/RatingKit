import Foundation

/// Persistence in UserDefaults (intentionally not Keychain — reinstalling the
/// host app should reset cooldowns by design).
final class RKStorage: @unchecked Sendable {

    private enum Key {
        static let deviceId = "rk.device_id"
        static let customerFullName = "rk.customer_full_name"
        static let lastShownAt = "rk.last_shown_at"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var deviceId: String {
        if let existing = defaults.string(forKey: Key.deviceId) {
            return existing
        }

        let new = UUID().uuidString
        defaults.set(new, forKey: Key.deviceId)

        return new
    }

    var customerFullName: String? {
        defaults.string(forKey: Key.customerFullName)
    }

    var lastShownAt: Date? {
        get { defaults.object(forKey: Key.lastShownAt) as? Date }
        set { defaults.set(newValue, forKey: Key.lastShownAt) }
    }

    func recordShown() {
        lastShownAt = Date()
    }

    func setDeviceId(_ id: String) {
        defaults.set(id, forKey: Key.deviceId)
    }

    func setCustomerFullName(_ fullName: String) {
        defaults.set(fullName, forKey: Key.customerFullName)
    }

    func reset() {
        defaults.removeObject(forKey: Key.deviceId)
        defaults.removeObject(forKey: Key.lastShownAt)
    }
}
