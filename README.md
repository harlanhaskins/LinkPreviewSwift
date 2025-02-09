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

// You can also provide custom headers to attach to the request

let preview = try await provider.load(from: url, headers: [
    "Authorization": "Bearer ..."
])

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

### Custom Processors

By default all the extraction is performed by `MetadataProcessor` objects. There
are currently three, `OpenGraphProcessor`, `GenericHTMLProcessor`, and
`WikipediaAPIProcessor`, the latter of which is specific to `wikipedia.org` URLs.

You can implement your own processor to recognize special pages and perform more
specific scraping tasks; you will be handed a `Document` from [SwiftSoup](https://github.com/scinfu/SwiftSoup)
that you can extract data from.

For example, you can add a processor that adds the URL to the end of the title like so:

```swift
enum CustomProcessor: MetadataProcessor {
    static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document?,
        options: MetadataProcessingOptions
    ) async {
        let title = preview.title ?? ""
        if let host = url.host {
            if !title.isEmpty {
                title += " • "
            }
            title += host
        }
        if !title.isEmpty {
            preview.title = title
        }
    }
}

// Tell the provider to run this processor along with the others.
provider.registerProcessor(CustomProcessor.self)

let preview = try await provider.load(from: URL(string: "https://example.com")!)

print(preview.title) // prints 'Example Domain • example.com'
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
