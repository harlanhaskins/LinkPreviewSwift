public import Foundation
import SwiftSoup

public enum LinkPreviewError: Error {
    case invalidResponse(URLResponse)
    case unsuccessfulHTTPStatus(Int, HTTPURLResponse)
    case unableToParseResponse(Error)
}

@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
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
        for (offset, key) in propertyNames.enumerated() {
            let property = properties[key]!
            if offset != 0 {
                description += "\n"
            }
            description += "\(property.name)"
            if let content = property.content {
                description += ": "
                if property.name == "description" && content.count > 200 {
                    description += "\"\(content.prefix(200))\" [truncated]"
                } else {
                    description += "\"\(content)\""
                }
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

extension URLRequest {
    mutating func setValueIfNotSet(_ value: String, forHTTPHeaderField field: String) {
        if self.value(forHTTPHeaderField: field) == nil {
            setValue(value, forHTTPHeaderField: field)
        }
    }
}
