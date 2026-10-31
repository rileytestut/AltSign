# Watch signing regression tests

On macOS, initialize submodules and run:

```sh
git submodule update --init --recursive
python3 Tests/run-watch-signing-tests.py
```

This compiles the production signing/model code, ldid, libplist and minizip directly. It avoids the unrelated GrandSlam/corecrypto link requirements of the full Swift package. Fixtures, certificates and synthetic CMS profiles are generated in a temporary directory and removed afterward. No Apple credentials, keychain signing identities or devices are used.

Coverage includes the exact `com.calebmech.Race` → `com.calebmech.Race.Z9NVYMZ644` companion mismatch, modern single-target Watch apps, watchOS 2-style nested extensions, watchOS 1-style nested apps, randomized IDs, ordinary iPhone apps/extensions, wrong profile families, missing HealthKit authorization, per-bundle profiles and entitlements, and strict nested signature/resource verification. A valid iOS-family profile without a literal watchOS Platform entry is accepted.

Optionally sign a disposable copy of an existing physical-device build:

```sh
python3 Tests/run-watch-signing-tests.py --app /path/to/Example.app
```

The original is read-only. This seeds HealthKit entitlements on the temporary copy, then remaps, provisions and signs it using synthetic test assets. Passing verifies code/resource integrity, not Apple trust, real profile/device coverage, installation, Watch sync or HealthKit runtime behavior.

The ldid submodule is temporarily pinned to the fork commit for https://github.com/rileytestut/ldid/pull/7 so recursive checkout is reproducible before the dependency merges. The integration suite fails against the original ldid backend because it strips the Watch HealthKit entitlement.
