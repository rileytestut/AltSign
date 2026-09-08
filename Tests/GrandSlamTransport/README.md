# GrandSlam transport regression tests

Run on macOS with Python 3 and Xcode command-line tools:

```sh
python3 Tests/GrandSlamTransport/test_transport.py
```

To retain machine-readable results:

```sh
python3 Tests/GrandSlamTransport/test_transport.py --results /tmp/altsign-gsa-results.json
```

The runner extracts `sendAuthenticationRequest` and `sendGrandSlamRequest` directly from the production Swift file, replacing only the GSA endpoint with an ephemeral loopback HTTP server. Minimal type shims avoid needing SRP, accounts, signing certificates, or the complete application. A test-only URLProtocol injects cancellation/offline failures into otherwise normal ephemeral sessions. Compilation and execution happen in a temporary directory.

The 17 cases cover:

- HTML 503 followed by a valid plist, using a separate connection for each attempt.
- Persistent 503: five total attempts, 1/2/4/8-second backoff, and the exchange deadline.
- Structured success and authentication challenges on HTTP 409/503, including a missing `ec` field, preserving existing GSA semantics.
- Incorrect credentials, invalid anisette, and arbitrary Apple error codes without retries, including structured errors returned with HTTP 503.
- Malformed HTML with HTTP 200/401 and unexpected plist shapes, without response-body or underlying parser-error leakage.
- Cancellation and offline errors without transport-helper retries.
- In-flight timeout, insufficient retry budget, and an already-expired deadline.
- Exactly one observed completion for each case and the modern User-Agent on GSA requests.

This is transport regression coverage on macOS Foundation. It does not perform live SRP, submit a two-factor code, validate an Apple account, prove the User-Agent's effect at Apple's edge, or replace iPhone installation/refresh testing. Timing checks assume a reasonably unloaded development machine. No Apple account, certificate, or network service beyond loopback is used.
