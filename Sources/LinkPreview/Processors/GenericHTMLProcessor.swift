//
//  GenericHTMLProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

import AsyncHTTPClient
public import Foundation
public import SwiftSoup

/// A metadata processor that tries to extract data from HTML outside of
/// OpenGraph, either by looking for `<title>` tags, `<meta name="description">` tags, `<link rel="icon">` tags, etc.
public enum GenericHTMLProcessor: MetadataProcessor {
    static let faviconProperties = ["icon", "shortcut icon", "apple-touch-icon", "apple-touch-icon-precomposed"]

    static func findFaviconURL(in document: Document) -> URL? {
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

    static func findCanonicalURL(in document: Document) -> URL? {
        guard let links = try? document.select("link[rel]") else {
            return nil
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
        return nil
    }

    private static func findDescription(in document: Document) -> String? {
        let metaTags = (try? document.select("meta[name]").array()) ?? []
        for metaTag in metaTags {
            let name = (try? metaTag.attr("name")) ?? ""
            if name.caseInsensitiveCompare("description") == .orderedSame {
                return try? metaTag.attr("content")
            }
        }

        return nil
    }

    private static func findTitle(in document: Document) -> String? {
        try? document.select("title").text()
    }

    private static func defaultFaviconIfExists(
        for url: URL
    ) async -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.path = "/favicon.ico"
        guard let url = components.url else {
            return nil
        }
        do {
            let request = HTTPClientRequest(url: url.absoluteString)
            let response = try await HTTPClient.shared.execute(request, timeout: .seconds(1))
            guard response.status == .ok else {
                return nil
            }
        } catch {
            return nil
        }

        return url
    }

    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document,
        options: MetadataProcessingOptions
    ) async {
        if preview.canonicalURL == nil {
            preview.canonicalURL = findCanonicalURL(in: document)
        }

        if preview.title == nil {
            preview.title = findTitle(in: document)
        }

        if preview.description == nil {
            preview.description = findDescription(in: document)
        }

        if preview.faviconURL == nil {
            preview.faviconURL = findFaviconURL(in: document)
        }

        if preview.faviconURL == nil && options.allowAdditionalRequests {
            preview.faviconURL = await defaultFaviconIfExists(for: url)
        }
    }
}
