import PackageDescription

let package = Package(
    name: "ToJyutpingSwift",
    products: [
        .library(
            name: "ToJyutpingSwift",
            targets: ["ToJyutpingSwift"]),
    ],
    targets: [
        .target(
            name: "ToJyutpingSwift",
            resources: [
                .process("data.txt")
            ]),
        .testTarget(
            name: "ToJyutpingSwiftTests",
            dependencies: ["ToJyutpingSwift"]
        ),
    ]
)
