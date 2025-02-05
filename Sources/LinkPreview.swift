import Foundation
import SwiftSoup

public struct OpenGraphProperty {
    public var name: String
    public var content: String?
    public var metadata: [String: String] = [:]
}

public struct OpenGraphMetadata {
    private let url: URL
    let properties: [String: OpenGraphProperty]

    public subscript<T: OpenGraphPropertyValue>(
        name: LinkPreviewPropertyName<T>
    ) -> T? {
        guard let value = properties[name.rawValue], let content = value.content else {
            return nil
        }

        return T.init(content: content, at: url)
    }

    init(document: Document, at url: URL) {
        var properties = [String: OpenGraphProperty]()
        let metaTags = try? document.select("meta[property]")
        for metaTag in metaTags?.array() ?? [] {
            guard var property = try? metaTag.attr("property") else {
                continue
            }
            if property.isEmpty { continue }
            if property.hasPrefix("og:") {
                property.removeFirst(3)
                guard let content = try? metaTag.attr("content") else {
                    continue
                }
                if property.contains(":") {
                    let pieces = property.split(separator: ":")
                    let title = String(pieces[0])
                    let metadataTitle = String(pieces[1])
                    properties[title, default: .init(name: title)].metadata[metadataTitle] = content
                } else {
                    properties[property, default: .init(name: property)].content = content
                }
            }
        }
        self.properties = properties
        self.url = url
    }
}

public protocol OpenGraphPropertyValue {
    init?(content: String, at url: URL)
}

extension String: OpenGraphPropertyValue {
    public init?(content: String, at url: URL) {
        self = content
    }
}

extension Int: OpenGraphPropertyValue {
    public init?(content: String, at url: URL) {
        self.init(content)
    }
}

extension UInt: OpenGraphPropertyValue {
    public init?(content: String, at url: URL) {
        self.init(content)
    }
}

extension URL: OpenGraphPropertyValue {
    public init?(content: String, at url: URL) {
        self.init(string: content, relativeTo: url.baseURL)
    }
}

public struct LinkPreviewPropertyName<Value: OpenGraphPropertyValue>: Sendable, Equatable {
    public var rawValue: String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static var description: LinkPreviewPropertyName<String> { .init("description") }
    public static var title: LinkPreviewPropertyName<String> { .init("title") }
    public static var imageURL: LinkPreviewPropertyName<URL> { .init("image") }
    public static var videoURL: LinkPreviewPropertyName<URL> { .init("video") }
    public static var audioURL: LinkPreviewPropertyName<URL> { .init("audio") }
}

public enum LinkPreviewError: Error {
    case invalidResponse(URLResponse)
    case unsuccessfulHTTPStatus(Int, HTTPURLResponse)
    case unableToParseResponse(Error)
}

public struct LinkPreview: CustomDebugStringConvertible {
    public var url: URL
    public var document: Document
    public var openGraph: OpenGraphMetadata

    static let faviconProperties = ["icon", "shortcut icon", "apple-touch-icon", "apple-touch-icon-precomposed"]
    public var faviconURL: URL? {
        guard let tags = try? document.select("link[rel]") else {
            return nil
        }
        for tag in tags {
            let rel = (try? tag.attr("rel")) ?? ""
            if Self.faviconProperties.contains(rel), let content = try? tag.absUrl("href") {
                return URL(string: content)
            }
        }
        return nil
    }

    public var hostFaviconURL: URL? {
        URL(string: "favicon.ico", relativeTo: url.baseURL)
    }

    public var canonicalURL: URL? {
        guard let links = try? document.select("link[rel]") else {
            return url
        }
        for link in links {
            do {
                if try link.attr("rel").caseInsensitiveCompare("canonical") == .orderedSame {
                    let url = try link.absUrl("href")
                    return URL(string: url)
                }
            } catch {
                continue
            }
        }
        return url
    }

    public init(html: String, url: URL) throws {
        self.url = url
        self.document = try SwiftSoup.parse(html, url.absoluteString)
        self.openGraph = OpenGraphMetadata(document: document, at: url)
    }

    private func findDescription() -> String? {
        let metaTags = (try? document.select("meta[name]").array()) ?? []
        for metaTag in metaTags {
            let name = (try? metaTag.attr("name")) ?? ""
            if name.caseInsensitiveCompare("description") == .orderedSame {
                return try? metaTag.attr("content")
            }
        }
        return nil
    }

    private func findTitle() -> String? {
        try? document.select("title").text()
    }

    public var description: String? {
        openGraph[.description] ?? findDescription()
    }

    public var title: String? {
        openGraph[.title] ?? findTitle()
    }

    public var imageURL: URL? {
        openGraph[.imageURL]
    }

    public var videoURL: URL? {
        openGraph[.videoURL]
    }

    public var audioURL: URL? {
        openGraph[.audioURL]
    }

    public var debugDescription: String {
        var description = ""
        for (offset, (_, property)) in openGraph.properties.enumerated() {
            if offset != 0 {
                description += "\n"
            }
            description += "\(property.name)"
            if let content = property.content {
                description += ": \"\(content)\""
            }
            if !property.metadata.isEmpty {
                for (field, content) in property.metadata {
                    description += "\n  \(field): \(content)"
                }
            }
        }
        return description
    }

    public static func load(
        with request: URLRequest,
        in session: URLSession = .shared
    ) async throws -> LinkPreview {
        var request = request
        request.setValueIfNotSet("facebookexternalhit/1.1 Facebot Twitterbot/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinkPreviewError.invalidResponse(response)
        }
        guard (200..<299).contains(httpResponse.statusCode) else {
            throw LinkPreviewError.unsuccessfulHTTPStatus(httpResponse.statusCode, httpResponse)
        }
        let html = String(decoding: data, as: UTF8.self)
        return try LinkPreview(html: html, url: httpResponse.url ?? request.url!)
    }

    public static func load(
        from url: URL,
        in session: URLSession = .shared
    ) async throws -> LinkPreview {
        try await load(with: URLRequest(url: url), in: session)
    }
}

extension URLRequest {
    mutating func setValueIfNotSet(_ value: String, forHTTPHeaderField field: String) {
        if self.value(forHTTPHeaderField: field) == nil {
            setValue(value, forHTTPHeaderField: field)
        }
    }
}
