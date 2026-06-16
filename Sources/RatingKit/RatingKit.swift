import Foundation
import SwiftUI

/// RatingKit — drop-in client SDK for requsting feedback and rating.
///
/// Usage in the host app:
///
///     @main
///     struct MyApp: App {
///         init() {
///             RatingKit.configure(
///                 apiKey: "rk_...",
///                 apiSecret: "rks_..."
///             )
///         }
///         var body: some Scene {
///             WindowGroup {
///                 ContentView()
///                     .ratingKitSheet()
///             }
///         }
///     }

/// Zero third-party dependencies — URLSession + Codable + SwiftUI only.
@MainActor
public final class RatingKit {

    public static let shared = RatingKit()

    public struct Config: Sendable {
        public var apiKey: String
        public var apiSecret: String
        public var minLaunchesBeforeAuto: Int
        /// If the app is backgrounded for at least this long, the next
        /// foreground entry counts as a fresh launch (increments launchCount).
        /// Matches the industry-standard 30-minute session-expiry rule
        /// (Google Analytics, Firebase, Mixpanel default). Set to 0 to count
        /// every foreground as a launch; set very high to count only cold
        /// launches.
        public var relaunchAfterBackgroundSeconds: TimeInterval

        public init(
            apiKey: String,
            apiSecret: String,
            minLaunchesBeforeAuto: Int = 3,
            relaunchAfterBackgroundSeconds: TimeInterval = 30 * 60
        ) {
            self.apiKey = apiKey
            self.apiSecret = apiSecret
            self.minLaunchesBeforeAuto = minLaunchesBeforeAuto
            self.relaunchAfterBackgroundSeconds = relaunchAfterBackgroundSeconds
        }
    }

    /// The backend URL the SDK talks to. Hardcoded to production so indie
    /// devs consuming this Swift Package don't need to think about it.
    /// Use `_setDevBaseURL(_:)` from a `#if DEBUG` block if you maintain
    /// the SDK and need to point at a local server.
    static let productionBaseURL = URL(string: "https://api.ratingkit.com")!
    private(set) var baseURL: URL = productionBaseURL

    /// Internal escape hatch for SDK maintainers to point at a local backend
    /// during development. The leading underscore + the explicit name signal
    /// "this is not part of the public package API". Call BEFORE `configure`.
    public static func _setDevBaseURL(_ url: URL) {
        shared.baseURL = url
    }

    private(set) var config: Config?
    let storage = RKStorage()
    private(set) lazy var client: RKClient = RKClient(kit: self)

    private init() {}

    /// Call once at app launch (e.g. in `App.init()`).
    public static func configure(apiKey: String, apiSecret: String) {
        configure(.init(apiKey: apiKey, apiSecret: apiSecret))
    }

    public static func configure(_ config: Config) {
        shared.config = config
        shared.storage.recordLaunch()
        RKForegroundTracker.shared.start()
    }

    /// Increment the launch counter manually (for hosts that want to bump it
    /// on screen visit rather than app launch).
    public static func recordLaunch() {
        shared.storage.recordLaunch()
    }

    /// Quick local check: did the user dismiss/complete recently? Avoids the
    /// network round-trip when we already know the answer is "not yet".
    public var localCooldownActive: Bool {
        if let dismissed = storage.lastDismissedAt {
            if Date().timeIntervalSince(dismissed) < RKCooldown.seconds { return true }
        }
        if storage.lastCompletedAt != nil { return true }
        return false
    }

    /// Programmatically open the sheet (e.g. from a "Send feedback" button).
    /// View modifiers attached via `.appFeedbackSheet()` listen for this and
    /// raise the sheet.
    public func present() {
        NotificationCenter.default.post(name: RatingKit.presentRequested, object: nil)
    }

    static let presentRequested = Notification.Name("com.ratingkit.RatingKit.presentRequested")

    /// Reset all stored state — useful for development. Don't call from prod.
    /// Re-records the current launch afterwards so launchCount reflects the
    /// session you're in (otherwise it reads 0 until next cold start, which
    /// is confusing during dev).
    public func resetForDevelopment() {
        storage.reset()
        storage.recordLaunch()
    }
}
