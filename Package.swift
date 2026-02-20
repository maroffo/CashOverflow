// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CashOverflow",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CashOverflow", targets: ["CashOverflow"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0"),
        .package(url: "https://github.com/google/generative-ai-swift.git", from: "0.5.0"),
    ],
    targets: [
        .target(
            name: "CashOverflow",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift"),
            ],
            path: "CashOverflow"
        )
    ]
)
