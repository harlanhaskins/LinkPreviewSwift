//
//  LinkPreviewProvider.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
import SwiftSoup

/// Loads and extracts metadata from web URLs.
public final class LinkPreviewProvider {
    static let defaultProcessors: [any MetadataProcessor.Type] = [
        OpenGraphProcessor.self,
        GenericHTMLProcessor.self,
        WikipediaAPIProcessor.self
    ]
    var registeredProcessors: [any MetadataProcessor.Type] = LinkPreviewProvider.defaultProcessors
    public var options: MetadataProcessingOptions = .init()

    public init() {
    }

    public func registerProcessor(_ type: any MetadataProcessor.Type) {
        if registeredProcessors.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(type) }) {
            return
        }
        registeredProcessors.append(type)
    }

    public func unregisterProcessor(_ type: any MetadataProcessor.Type) {
        guard let index = registeredProcessors.firstIndex(where: { ObjectIdentifier($0) == ObjectIdentifier(type) }) else {
            return
        }
        registeredProcessors.remove(at: index)
    }

    public func load(html: String, url: URL) async throws -> LinkPreview {
        var preview = LinkPreview(url: url)
        let document = try SwiftSoup.parse(html, url.absoluteString)
        for processor in registeredProcessors {
            await processor.updateLinkPreview(
                &preview,
                for: url,
                document: document,
                options: options
            )
        }
        return preview
    }

    /// Loads a link preview from the provided URL, optionally providing a set
    /// of custom headers.
    public func load(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> LinkPreview {
        var httpRequest = LinkPreviewURLRequest(url: url)
        for (header, value) in headers {
            httpRequest.setValue(value, forHTTPHeaderField: header)
        }
        httpRequest.setValue("facebookexternalhit/1.1 Facebot Twitterbot/1.0", forHTTPHeaderField: "User-Agent")
        let data = try await httpRequest.load()
        let html = String(decoding: data, as: UTF8.self)
        return try await load(html: html, url: url)
    }
}
