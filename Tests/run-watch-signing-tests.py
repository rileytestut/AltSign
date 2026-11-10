#!/usr/bin/env python3
"""Compile the production signing code and exercise it without Apple credentials/devices.

Requires macOS, Xcode command-line tools, Python 3 and initialized submodules.
All certificates, profiles and app bundles are disposable synthetic fixtures.
"""
import argparse
import concurrent.futures
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--app", type=Path, help="Also sign a disposable copy of an existing iOS app with a Watch companion")
args = parser.parse_args()


def run(args, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, **kwargs)


with tempfile.TemporaryDirectory(prefix="altsign-watch-tests-") as tmp:
    work = Path(tmp)
    ssl = ROOT / "Dependencies/OpenSSL/Frameworks/macosx"
    framework = ROOT / "Dependencies/OpenSSL/Frameworks/OpenSSL.xcframework/macos-arm64_x86_64"
    # The checked-in OpenSSL framework provides both Intel and Apple Silicon slices.
    if not (framework / "OpenSSL.framework").exists():
        framework = next(p.parent for p in (ROOT / "Dependencies/OpenSSL/Frameworks/OpenSSL.xcframework").glob("*/OpenSSL.framework") if "macos" in p.parent.name and "catalyst" not in p.parent.name)
    includes = [ROOT / "AltSign/include/AltSign", ROOT / "AltSign/ldid", ROOT / "Dependencies/ldid", ROOT / "Dependencies/minizip", ssl / "include", ROOT / "Dependencies/ldid/libplist/include", ROOT / "Dependencies/ldid/libplist/src", ROOT / "Dependencies/ldid/libplist/libcnary/include"]
    flags = ["-g", "-O0", "-Wno-deprecated-declarations", "-Wno-nullability-completeness", "-Dunix=1"]
    for path in includes:
        flags += ["-I", str(path)]
    flags += ["-F", str(framework)]
    sources = [ROOT / p for p in [
        "AltSign/Model/ALTApplication.mm", "AltSign/Model/Apple API/ALTProvisioningProfile.m",
        "AltSign/Model/Apple API/ALTCertificate.m", "AltSign/Model/Apple API/ALTTeam.m",
        "AltSign/Signing/ALTSigner.mm", "AltSign/Capabilities/ALTCapabilities.m",
        "AltSign/Categories/NSError+ALTErrors.m", "AltSign/Categories/NSFileManager+Zip.m",
        "AltSign/ldid/alt_ldid.cpp", "Dependencies/ldid/lookup2.c",
        "Dependencies/minizip/ioapi.c", "Dependencies/minizip/unzip.c", "Dependencies/minizip/zip.c",
        "Tests/WatchSigningTests.m",
    ]]
    sources += list((ROOT / "Dependencies/ldid/libplist/src").glob("*.c"))
    sources += [p for p in (ROOT / "Dependencies/ldid/libplist/libcnary").glob("*.c") if p.name != "cnary.c"]

    def compile_source(item):
        index, source = item
        obj = work / f"{index}.o"
        cxx = source.suffix in (".mm", ".cpp")
        command = ["xcrun", "clang++" if cxx else "clang", *flags]
        if cxx:
            command += ["-std=c++14"]
        if source.suffix in (".m", ".mm"):
            command += ["-fobjc-arc", "-fblocks"]
        run([*command, "-c", source, "-o", obj], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return obj

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
            objects = list(executor.map(compile_source, enumerate(sources)))
    except subprocess.CalledProcessError as error:
        print(error.stderr.decode())
        raise
    binary = work / "WatchSigningTests"
    run(["xcrun", "clang++", *objects, "-o", binary, "-framework", "Foundation", "-framework", "Security", "-F", framework, "-framework", "OpenSSL", "-lz", "-Wl,-rpath," + str(framework)])

    # A new local test identity for each run; never reads the user's keychain.
    run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-keyout", work / "key.pem", "-out", work / "cert.pem", "-days", "1", "-addext", "basicConstraints=critical,CA:FALSE", "-addext", "keyUsage=critical,digitalSignature", "-addext", "extendedKeyUsage=critical,codeSigning", "-subj", "/CN=AltSign Watch Tests/OU=Z9NVYMZ644/O=AltSign Tests/C=US"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    run(["openssl", "pkcs12", "-export", "-inkey", work / "key.pem", "-in", work / "cert.pem", "-out", work / "test.p12", "-passout", "pass:"])
    (work / "main.c").write_text("int main(void) { return 0; }\n")
    run(["xcrun", "clang", work / "main.c", "-o", work / "Executable"])
    run([binary, work, *([args.app.resolve()] if args.app else [])])
