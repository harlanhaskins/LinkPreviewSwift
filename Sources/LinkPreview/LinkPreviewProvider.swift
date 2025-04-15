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
    private static let defaultProcessors: [any MetadataProcessor.Type] = [
        OpenGraphProcessor.self,
        GenericHTMLProcessor.self,
        WikipediaAPIProcessor.self
    ]

    private var registeredProcessors: [any MetadataProcessor.Type]
    public var options: MetadataProcessingOptions = .init()

    public init() {
        self.registeredProcessors = LinkPreviewProvider.defaultProcessors
    }

    public init(processors: [any MetadataProcessor.Type]) {
        self.registeredProcessors = processors
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
        await runProcessors(&preview, document: document, url: url)
        return preview
    }

    func runProcessors(_ preview: inout LinkPreview, document: Document?, url: URL) async {
        for processor in registeredProcessors where shouldRunProcessor(processor: processor, url: url) {
            await processor.updateLinkPreview(
                &preview,
                for: url,
                document: document,
                options: options
            )
        }
    }

    func shouldRunProcessor(processor: any MetadataProcessor.Type, url: URL) -> Bool {
        return switch processor.activationRule {
        case .always: true

        case .includesHostnames(let hostnames):
            hostnames.contains(where: { $0 == url.baseHostName })

        case .excludesHostnames(let hostnames):
            !hostnames.contains(where: { $0 == url.baseHostName })
        }
    }

    private func bestUserAgent(for url: URL) -> String {
        let matchingHostName = self.options.websiteSpecificUserAgents.first(where: { $0.hostname == url.baseHostName })
        return if let matchingHostName {
            matchingHostName.userAgent
        } else {
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.4 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.4 facebookexternalhit/1.1 Facebot Twitterbot/1.0"
        }
    }

    /// Loads a link preview from the provided URL, optionally providing a set
    /// of custom headers.
    public func load(
        from url: URL,
        headers: [String: String] = [:]
    ) async throws -> LinkPreview {
		var httpRequest = LinkPreviewURLRequest(url: url, timeout: options.requestTimeout)
        for (header, value) in headers {
            httpRequest.setValue(value, forHTTPHeaderField: header)
        }
        httpRequest.setValue(bestUserAgent(for: url), forHTTPHeaderField: "User-Agent")
        httpRequest.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        var preview = LinkPreview(url: url)
        var document: Document?
        switch try await httpRequest.load() {
        case let .html(data):
            let html = String(decoding: data, as: UTF8.self)
            document = try SwiftSoup.parse(html, url.absoluteString)
        case let .fileURL(url, contentType):
            preview.canonicalURL = url
            if contentType.localizedCaseInsensitiveContains("image/") {
                preview.imageURL = url
            } else if contentType.localizedCaseInsensitiveContains("audio/") {
                preview.audioURL = url
            } else if contentType.localizedCaseInsensitiveContains("video/") {
                preview.videoURL = url
            }
            preview.title = url.lastPathComponent
        }
        await runProcessors(&preview, document: document, url: url)
        return preview
    }
}
