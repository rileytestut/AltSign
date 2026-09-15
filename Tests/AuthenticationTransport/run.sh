#!/bin/sh
set -eu
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/altsign-auth-tests.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
mkdir -p "$test_dir/Sources/AuthenticationTransport" "$test_dir/Tests/AuthenticationTransportTests"
cp "$repo_root/AltSign/Sources/ALTAuthenticationTransport.swift" "$test_dir/Sources/AuthenticationTransport/"
cp "$repo_root/Tests/AuthenticationTransport/TransportTests.swift" "$test_dir/Tests/AuthenticationTransportTests/"
cat > "$test_dir/Package.swift" <<'PACKAGE'
// swift-tools-version:5.3
import PackageDescription
let package = Package(name: "AuthenticationTransportTests", platforms: [.macOS(.v11)], targets: [
    .target(name: "AuthenticationTransport"),
    .testTarget(name: "AuthenticationTransportTests", dependencies: ["AuthenticationTransport"])
])
PACKAGE
# Compile the actual production source without CoreCrypto/OpenSSL or Apple credentials.
xcrun swift test --package-path "$test_dir" --scratch-path "$test_dir/.build"
