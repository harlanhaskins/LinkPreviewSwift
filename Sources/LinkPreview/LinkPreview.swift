public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif
import SwiftSoup

public enum LinkPreviewError: Error {
    case invalidResponse(URLResponse)
    case unsuccessfulHTTPStatus(Int, HTTPURLResponse)
    case unableToParseResponse(Error)
}

public struct LinkPreview: CustomDebugStringConvertible, Sendable {
    public let url: URL
    public internal(set) var properties: [String: LinkPreviewProperty]

    public init(url: URL, properties: [String: LinkPreviewProperty] = [:]) {
        self.url = url
        self.properties = properties
    }

    public func property<T>(named name: LinkPreviewPropertyName<T>) -> LinkPreviewProperty? {
        properties[name.rawValue]
    }

    public func property(named name: String) -> LinkPreviewProperty? {
        properties[name]
    }

    public subscript<T: LinkPreviewPropertyValue>(
        name: LinkPreviewPropertyName<T>
    ) -> T? {
        get {
            guard let value = properties[name.rawValue], let content = value.content else {
                return nil
            }

            return T.init(content: content, at: url)
        }
        set {
            let property = LinkPreviewProperty(name: name.rawValue, content: newValue?.content)
            if properties.keys.contains(name.rawValue) {
                properties[name.rawValue]?.merge(with: property)
            } else {
                properties[name.rawValue] = property
            }
        }
    }

    public var hostFaviconURL: URL? {
        URL(string: "favicon.ico", relativeTo: url.baseURL)
    }

    public var canonicalURL: URL? {
        get { self[.canonicalURL] }
        set { self[.canonicalURL] = newValue }
    }

    public var faviconURL: URL? {
        get { self[.faviconURL] }
        set { self[.faviconURL] = newValue }
    }

    public var description: String? {
        get { self[.description] }
        set { self[.description] = newValue }
    }

    public var title: String? {
        get { self[.title] }
        set { self[.title] = newValue }
    }

    public var imageURL: URL? {
        get { self[.imageURL] }
        set { self[.imageURL] = newValue }
    }

    public var videoURL: URL? {
        get { self[.videoURL] }
        set { self[.videoURL] = newValue }
    }

    public var audioURL: URL? {
        get { self[.audioURL] }
        set { self[.audioURL] = newValue }
    }

    public var debugDescription: String {
        var description = ""
        let propertyNames = properties.keys.sorted()
        var numberPrinted = 0
        for key in propertyNames {
            let property = properties[key]!
            guard let content = property.content else {
                continue
            }
            if numberPrinted != 0 {
                description += "\n"
            }
            numberPrinted += 1
            description += "\(property.name): "
            if property.name == "description" && content.count > 200 {
                description += "\"\(content.prefix(200))\" [truncated]"
            } else {
                description += "\"\(content)\""
            }
            if !property.metadata.isEmpty {
                let keys = property.metadata.keys.sorted()
                for key in keys {
                    description += "\n  \(key): \(property.metadata[key]!)"
                }
            }
        }
        return description
    }
}
