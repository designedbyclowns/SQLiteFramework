// swift-tools-version:5.8

import Foundation
import PackageDescription

var globalSwiftSettings: [PackageDescription.SwiftSetting] = []
// Only enable these additional checker settings if the environment variable
// `LOCAL_BUILD` is set. Previous value of `CI` was a poor choice because iOS
// apps in GitHub Actions would trigger this as unsafe flags and fail builds
// when using a released library.
if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
    globalSwiftSettings.append(.enableExperimentalFeature("StrictConcurrency"))
}

// let FFIbinaryTarget: PackageDescription.Target
// if ProcessInfo.processInfo.environment["LOCAL_BUILD"] != nil {
//     FFIbinaryTarget = .binaryTarget(
//         name: "fullsqlite3",
//         path: "./fullsqlite3.xcframework.zip"
//     )
// } else {
//     FFIbinaryTarget = .binaryTarget(
//         name: "fullsqlite3",
//         url: "https://github.com/designedbyclowns/SQLiteFramework/releases/download/0.0.1/fullsqlite3.xcframework.zip",
//         checksum: "d94106d28a64661999c5eae402c73372460385fb370ceb4b4803dced7a524e93"
//     )
// }

let package = Package(
    name: "GeoSQLite",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "GeoSQLite",
            targets: ["GeoSQLite"]),
    ],
    targets: [
        .target(
            name: "GeoSQLite",
            dependencies: ["fullsqlite3"],
            swiftSettings: globalSwiftSettings
        ),
        .testTarget(
            name: "GeoSQLiteTests",
            dependencies: ["GeoSQLite", "fullsqlite3"]
        ),
        .binaryTarget(
            name: "fullsqlite3",
            path: "../fullsqlite3.xcframework.zip"
        )
    ]
)
