import Testing
import Foundation
@testable import RatingKit

/// The API key is never committed — supply it at runtime via the `RK_API_KEY`
/// environment variable. See `README.md` in this directory for how to run.
private let apiKey = ProcessInfo.processInfo.environment["RK_API_KEY"]

@MainActor
@Suite(.enabled(if: apiKey != nil, "Set RK_API_KEY to run the live RKClient tests"))
struct RKClientLiveTests {

    @Test func postsReviewToLiveServer() async throws {
        let key = try #require(apiKey)

        RatingKit.configure(.init(apiKey: key))
        RatingKit.setDeviceId("rk-integration-test")

        // Exercises the real RKClient.post path: builds the request, posts to
        // /api/v1/reviews with Bearer auth + device/timestamp headers, and
        // decodes the response. Throws on any non-2xx / decode / transport error.
        try await RatingKit.shared.client.postRating(
            rating: .init(rating: 5, feedback: "Integration test review")
        )
    }
}
