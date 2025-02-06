//
//  GenericHTMLProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
public import SwiftSoup

public enum GenericHTMLProcessor: MetadataProcessor {
    public static func applies(to url: URL) -> Bool {
        true
    }

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

    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document,
        in session: URLSession
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
    }
}
