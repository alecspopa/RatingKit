# RatingKit Tests

## Live `RKClient` integration test

`RKClientTests.swift` contains a live integration test that posts a real review
to the RatingKit server via `RKClient`. It verifies the end-to-end request path:
URL, `Bearer` auth header, device/timestamp headers, JSON body, and response
decoding.

### API key

The test reads the API key from the `RK_API_KEY` environment variable.
If `RK_API_KEY` is not set, the live suite is
reported as **skipped**, so a normal test run stays offline.

### Running

This is an iOS-only Swift package, so run the tests on an iOS Simulator with
`xcodebuild`. When testing on a simulator, environment variables must be
forwarded to the test runner with the `TEST_RUNNER_` prefix (xcodebuild strips
the prefix before the test process sees it):

```sh
TEST_RUNNER_RK_API_KEY="<your-api-key>" \
xcodebuild test \
  -scheme RatingKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Without `TEST_RUNNER_RK_API_KEY`, the same command runs and the live suite is
skipped:

```sh
xcodebuild test \
  -scheme RatingKit \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

A non-2xx response, decode failure, or transport error surfaces as a test
failure with the underlying `RKClient.RKError`.
