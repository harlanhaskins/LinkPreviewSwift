//
//  LinkPreviewProperty.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
import SwiftSoup

public struct LinkPreviewPropertyName<Value: LinkPreviewPropertyValue>: Sendable, Equatable {
    public var rawValue: String
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static var description: LinkPreviewPropertyName<String> { .init("description") }
    public static var title: LinkPreviewPropertyName<String> { .init("title") }
    public static var canonicalURL: LinkPreviewPropertyName<URL> { .init("url") }
    public static var imageURL: LinkPreviewPropertyName<URL> { .init("image") }
    public static var videoURL: LinkPreviewPropertyName<URL> { .init("video") }
    public static var audioURL: LinkPreviewPropertyName<URL> { .init("audio") }
    public static var faviconURL: LinkPreviewPropertyName<URL> { .init("icon") }
}

/// A property within a link preview, including any associated metadata.
public struct LinkPreviewProperty: Sendable {
    /// The name of the property ("title", "description", etc).
    public var name: String

    /// The content extracted from the page for this property.
    public var content: String?

    /// Any sub-properties associated with this property.
    public var metadata: [String: String] = [:]

    mutating func merge(with property: LinkPreviewProperty) {
        if content == nil {
            content = property.content
        }

        for (key, value) in property.metadata {
            if metadata[key] == nil {
                metadata[key] = value
            }
        }
    }
}

public protocol LinkPreviewPropertyValue: Sendable {
    init?(content: String, at url: URL)
    var content: String { get }
}

extension String: LinkPreviewPropertyValue {
    public init?(content: String, at url: URL) {
        self = content
    }
    public var content: String {
        self
    }
}

extension Int: LinkPreviewPropertyValue {
    public init?(content: String, at url: URL) {
        self.init(content)
    }
    public var content: String {
        "\(self)"
    }
}

extension UInt: LinkPreviewPropertyValue {
    public init?(content: String, at url: URL) {
        self.init(content)
    }
    public var content: String {
        "\(self)"
    }
}

extension URL: LinkPreviewPropertyValue {
    public init?(content: String, at url: URL) {
        self.init(string: content, relativeTo: url.baseURL)
    }
    public var content: String {
        absoluteString
    }
}
