# RatingKit

Drop-in client SDK for requsting rating and feedback in iOS 17+ apps.
Apps with good ratings rank much better in the App Store than those without.

Zero third-party dependencies — URLSession + Codable + SwiftUI - all system frameworks.
No ATT prompt. No IDFA. No location, contacts, or photos. No cross-app tracking.
Privacy manifest (PrivacyInfo.xcprivacy) bundled — merges into your host app at build time.
iOS 17+.

## Install

Xcode → File → Add Package Dependencies… and paste:

```
https://github.com/alecspopa/RatingKit.git
```

Or in your Package.swift:

```
.package(url: "https://github.com/alecspopa/RatingKit.git", from: "1.0.0"),
```

### Get your API keys

Sign up at [ratingkit.slowcookingsoftware.com](https://ratingkit.slowcookingsoftware.com/), create a project, and copy the apiKey from the project page.

### Usage in the host app:

1. In your app's `App.swift`:

```swift
    import SwiftUI
    
    @main
    struct MyApp: App {
        init() {
            RatingKit.configure(
                apiKey: "a59b7a...",
            )
        }
    }
```

2. In your view where you want to ask for rating

```swift
    import SwiftUI
    import RatingKit
    
    struct ContentView: View {
        @State private var isPresented: Bool = false

        var body: some View {
            VStack {
                Text("Hello RatingKit!")
            }
            .appRatingSheet(isPresented: $isPresented)
        }
    }
```

Note: We recommend asking for rating after a successful action was completed to increase your likelihood of receiving a good review.

## Apple App Store privacy compliance

The SDK ships a PrivacyInfo.xcprivacy manifest at Sources/RatingKit/PrivacyInfo.xcprivacy. Xcode merges it with your host app's manifest at build time. Host apps embedding RatingKit MUST also do the following before submitting to the App Store:

1. Ship your own PrivacyInfo.xcprivacy

Even with the SDK manifest, your app needs its own (declaring any APIs your code uses). The SDK's manifest will merge in automatically.

2. Update App Store Connect → App Privacy → Privacy Nutrition Label

Declare these data types RatingKit collects (all "Not Linked to User", "Not Used for Tracking"):

| Data type          	| Purpose                                               |
| --------------------- | ----------------------------------------------------- |
| Other User Content    | App Functionality, Analytics, Product Personalization |
| Other Diagnostic Data | Analytics, App Functionality                          |
| Product Interaction   | Analytics, Product Personalization                    |

3. Add a paragraph to your privacy policy

Suggested wording, copy-pasteable:

> We use RatingKit to collect anonymous in-app feedback. When you submit your feedback we transmit your answer, app version, device model, OS version, locale. An opaque random identifier (UUID) is generated on your device to deduplicate responses; it is stored only in this app's local preferences and resets if you reinstall. We do not collect your name, email, device advertising identifier (IDFA), location, contacts, or any data from outside this app. We do not track you across apps or websites.

4. Don't ship in Kids-Category apps without extra work

Apple's Kids Category requires parental-consent infrastructure. RatingKit doesn't include any. Don't drop it into a Kids app without first wiring up a COPPA-compliant consent gate.

5. What's deliberately NOT collected (so you don't have to declare these)

- IDFA / device advertising identifier (would require ATT prompt — we never request)
- Location, contacts, calendar, photos, microphone, camera (no permissions touched)
- Persistent identity that survives reinstall (UUID intentionally lives in UserDefaults, not Keychain)
- Cross-app or cross-website tracking signals
- Apple-proprietary StoreKit data beyond entitlement product IDs + dates

### What gets sent over the wire

Every request to the RatingKit backend is sent over HTTPS and contains the apiKey in the header. 

Each request body includes:
Device context (passive, no permissions): app version, build, bundle id, OS version, device class + model, locale + region + preferred languages, timezone, opaque device UUID.
Feedback text when given by the user.

## Pricing

Less than a cheap shared server. I am fully aware that I have not built anything revolutionary with RatingKit and that anyone can vibe-code the backend for this in an afternoon, but does it worh the hassel when you can just use RatingKit for less than it's costing you to host your own backend?

## License

MIT — see [LICENSE](https://github.com/alecspopa/RatingKit/blob/main/LICENSE). The SwiftUI client is open source. The hosted dashboard backend is a separately operated, closed-source service.
