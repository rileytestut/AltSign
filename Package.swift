// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

let package = Package(
    name: "AltSign",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
    ],
    products: [
        .library(
            name: "AltSign-Dynamic",
            type: .dynamic,
            targets: ["AltSign", "CAltSign", "CoreCrypto", "CCoreCrypto", "ldid", "ldid-core", "OpenSSL"]
        ),
        .library(
            name: "AltSign-Static",
            targets: ["AltSign", "CAltSign", "CoreCrypto", "CCoreCrypto", "ldid", "ldid-core"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "OpenSSL",
            path: "Dependencies/OpenSSL/Frameworks/OpenSSL.xcframework"
        ),
        
        .target(
            name: "ldid-core",
            path: "Dependencies/ldid",
            exclude: [
                "ldid.hpp",
                "ldid.cpp",
                "version.sh",
                "COPYING",
                "control.sh",
                "control",
                "ios.sh",
                "make.sh",
                "deb.sh",
                "plist.sh",
                "libplist/include",
                "libplist/include/Makefile.am",
                "libplist/fuzz",
                "libplist/cython",
                "libplist/m4",
                "libplist/test",
                "libplist/tools",
                "libplist/AUTHORS",
                "libplist/autogen.sh",
                "libplist/configure.ac",
                "libplist/COPYING",
                "libplist/COPYING.LESSER",
                "libplist/doxygen.cfg.in",
                "libplist/Makefile.am",
                "libplist/NEWS",
                "libplist/README.md",
                "libplist/src/Makefile.am",
                "libplist/src/libplist++.pc.in",
                "libplist/src/libplist.pc.in",
                "libplist/libcnary/cnary.c",
                "libplist/libcnary/COPYING",
                "libplist/libcnary/Makefile.am",
                "libplist/libcnary/README",
            ],
            sources: [
                "lookup2.c",
                "libplist/src",
                "libplist/libcnary",
                "libplist/libcnary/src",
            ],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("libplist/include"),
                .headerSearchPath("libplist/src"),
                .headerSearchPath("libplist/libcnary/include"),
                .headerSearchPath("../OpenSSL/ios/include"),
            ]
        ),
        .target(
            name: "ldid",
            dependencies: ["ldid-core"],
            path: "AltSign/ldid",
            exclude: [
                "alt_ldid.hpp",
            ],
            sources: [
                "alt_ldid.cpp",
            ],
            publicHeadersPath: "",
            cSettings: [
                .headerSearchPath("../../Dependencies/ldid"),
                .headerSearchPath("../../Dependencies/ldid/libplist/include"),
                .headerSearchPath("../../Dependencies/ldid/libplist/src"),
                .headerSearchPath("../../Dependencies/ldid/libplist/libcnary/include"),
                .headerSearchPath("../../Dependencies/OpenSSL/ios/include"),
            ]
        ),
        
        .target(
            name: "CCoreCrypto",
            path: "Dependencies/corecrypto",
            exclude: [
                "Sources/CoreCryptoMacros.swift"
            ],
            cSettings: [
                .headerSearchPath("include/corecrypto"),
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1")
            ]
        ),
        .target(
            name: "CoreCrypto",
            dependencies: ["CCoreCrypto"],
            path: "Dependencies/corecrypto/Sources",
            exclude: [
                "ccsrp.m"
            ],
            sources: [
                "CoreCryptoMacros.swift"
            ],
            cSettings: [
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1")
            ]
        ),

        .target(
            name: "CAltSign",
            dependencies: ["CoreCrypto", "ldid"],
            path: "",
            exclude: [
                "AltSign/ldid/alt_ldid.cpp",
                "AltSign/ldid/alt_ldid.hpp",
                "AltSign/Sources",
                "AltSign/include/module.modulemap",
                "Dependencies/corecrypto",
                "Dependencies/ldid",
                "Dependencies/OpenSSL",
                "Dependencies/minizip/iowin32.c",
                "Dependencies/minizip/Makefile",
                "Dependencies/minizip/minizip.c",
                "Dependencies/minizip/miniunz.c",
                "Dependencies/minizip/ChangeLogUnzip",
            ],
            publicHeadersPath: "AltSign/include",
            cSettings: [
                .headerSearchPath("AltSign/**"),
                .headerSearchPath("AltSign/ldid"),
                .headerSearchPath("Dependencies/minizip"),
                .headerSearchPath("AltSign/Capabilities"),
                .headerSearchPath("Dependencies/OpenSSL/ios/include"),
                .headerSearchPath("Dependencies/ldid/libplist/include"),
                .headerSearchPath("Dependencies/ldid"),
                .define("unix=1"),
            ],
            linkerSettings: [
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("Security"),
            ]
        ),
        .target(
            name: "AltSign",
            dependencies: ["CAltSign"],
            path: "AltSign/Sources",
            cSettings: [
                .headerSearchPath("Dependencies/minizip"),
                .define("CORECRYPTO_DONOT_USE_TRANSPARENT_UNION=1"),
            ]
        )
    ],
    
    cLanguageStandard: CLanguageStandard.gnu11,
    cxxLanguageStandard: .cxx14
)
