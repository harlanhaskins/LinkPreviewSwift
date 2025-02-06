# LinkPreviewSwift

LinkPreviewSwift is an in-progress implementation of link previews in Swift that works client-side or server-side.

## Usage

Similarly to the [LinkPresentation](https://developer.apple.com/documentation/linkpresentation) framework, you create an instance of `LinkPreviewProvider`
that you can configure to load link previews for you.

```swift
let provider = LinkPreviewProvider()

// Optionally, configure the provider:

// Turn off processing that requires making additional requests for more information,
// instead choosing only to read data from the single page that's loaded.
provider.options.allowAdditionalRequests

// Load the preview
let preview = try await provider.load(from: url)

// If you want to customize the request before sending it, you can do that.
var request = URLRequext(url: url)
request.setValue("Bearer ...", forHTTPHeaderField: "Authorization")
let preview = try await provider.load(with: request)

// You can also load directly from HTML
let html = "<html><head><title>Title</title></head></html>"
let preview = try await provider.load(html: html, url: URL(string: "example.com")!)
```

The `LinkPreview` type has several accessors for common OpenGraph metadata:

```swift
let imageURL = preview.imageURL
let title = preview.title
let description = preview.description
```

But you can also read custom OpenGraph fields directly from the properties:

```swift
// Parses `og:image`, `og:image:width`, and `og:image:height` tags.
let imageURLProperty = preview.property(named: "image")
let imageURL = imageURLProperty.content

if let width = imageURLProperty.metadata["width"], 
    let height = imageURLProperty.metadata["height"] {
    // Parse size as integers.
}
```

## Installation

LinkPreviewSwift can be added to your project using Swift Package Manager. For more
information on using SwiftPM in Xcode, see [Apple's guide](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

If you're using package dependencies directly, you can add this as one of your dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/harlanhaskins/LinkPreviewSwift.git", branch: "main")
]
```

## Author

Harlan Haskins ([harlan@harlanhaskins.com](mailto:harlan@harlanhaskins.com))
