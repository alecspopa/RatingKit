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
///     }
///
///     struct ContentView: View {
///         @State private var isPresented: Bool = false
///
///         var body: some View {
///             VStack {
///                 Text("Hello RatingKit!")
///             }
///             .ratingSheet(isPresented: $isPresented)
///         }

/// Zero third-party dependencies — URLSession + Codable + SwiftUI only.
@MainActor
public final class RatingKit {

    public static let shared = RatingKit()

    public struct Config: Sendable {
        public var apiKey: String
        public var apiURL: URL

        public init(
            apiKey: String,
            apiURL: URL = URL(string: "https://api.ratingkit.com")!
        ) {
            self.apiKey = apiKey
            self.apiURL = apiURL
        }
    }

    private(set) var config: Config?
    let storage = RKStorage()
    private(set) lazy var client: RKClient = RKClient(kit: self)

    private init() {}

    /// Call once at app launch (e.g. in `App.init()`).
    public static func configure(apiKey: String, apiURL: URL) {
        configure(.init(apiKey: apiKey, apiURL: apiURL))
    }

    public static func configure(_ config: Config) {
        shared.config = config
    }

    public static func setDeviceId(_ deviceId: String) {
        shared.storage.setDeviceId(deviceId)
    }

    public static func setCustomerFullName(_ fullName: String) {
        shared.storage.setCustomerFullName(fullName)
    }

    /// Reset all stored state — useful for development. Don't call from prod.
    public func resetForDevelopment() {
        storage.reset()
    }
}
