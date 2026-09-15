# Authentication transport tests

Run on macOS with Xcode selected:

```sh
Tests/AuthenticationTransport/run.sh
```

The script copies the production Foundation-only transport unchanged into a temporary Swift package and runs XCTest against a custom URLProtocol. It does not initialize crypto submodules, use Apple credentials, or contact Apple. Temporary sources and build products are removed on exit.

Timing tests use short injected policy values. The shipping defaults (12-second spacing, 60-second fallback for HTTP 429, 120-second request budget) are conservative local policy choices, not documented Apple limits. They need broader end-to-end validation before release.
