//
//  LinkPreviewProvider.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif
import SwiftSoup

/// Loads and extracts metadata from web URLs.
public final class LinkPreviewProvider {
    static let defaultProcessors: [any MetadataProcessor.Type] = [
        OpenGraphProcessor.self,
        GenericHTMLProcessor.self,
        WikipediaAPIProcessor.self
    ]
    let urlSession: URLSession
    var registeredProcessors: [any MetadataProcessor.Type] = LinkPreviewProvider.defaultProcessors
    public var options: MetadataProcessingOptions = .init()

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
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

    public func load(with request: URLRequest) async throws -> LinkPreview {
        var request = request
        request.setValueIfNotSet("facebookexternalhit/1.1 Facebot Twitterbot/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinkPreviewError.invalidResponse(response)
        }
        guard (200..<299).contains(httpResponse.statusCode) else {
            throw LinkPreviewError.unsuccessfulHTTPStatus(httpResponse.statusCode, httpResponse)
        }
        let html = String(decoding: data, as: UTF8.self)
        let url = httpResponse.url ?? request.url!
        return try await load(html: html, url: url)
    }

    public func load(html: String, url: URL) async throws -> LinkPreview {
        var preview = LinkPreview(url: url)
        let document = try SwiftSoup.parse(html, url.absoluteString)
        for processor in registeredProcessors {
            guard processor.applies(to: url) else {
                continue
            }
            await processor.updateLinkPreview(
                &preview,
                for: url,
                document: document,
                in: urlSession,
                options: options
            )
        }
        return preview
    }

    public func load(from url: URL) async throws -> LinkPreview {
        try await load(with: URLRequest(url: url))
    }
}
