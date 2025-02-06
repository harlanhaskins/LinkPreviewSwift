//
//  OpenGraphProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
public import SwiftSoup

public enum OpenGraphProcessor: MetadataProcessor {
    public static func applies(to url: URL) -> Bool {
        true
    }

    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document,
        in session: URLSession
    ) async {
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
                    preview.properties[title, default: .init(name: title)].metadata[metadataTitle] = content
                } else {
                    preview.properties[property, default: .init(name: property)].content = content
                }
            }
        }
    }
}
