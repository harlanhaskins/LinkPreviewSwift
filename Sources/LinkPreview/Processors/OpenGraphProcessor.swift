//
//  OpenGraphProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
public import SwiftSoup

public enum OpenGraphProcessor: MetadataProcessor {
    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document?,
        options: MetadataProcessingOptions
    ) async {
        guard let document else {
            return
        }
        let metaTags = try? document.select("meta[property]")
        for metaTag in metaTags?.array() ?? [] {
            guard let propertyTag = try? metaTag.attr("property") else {
                continue
            }
            var components = propertyTag.split(separator: ":")
            if components.count == 1 { continue }

            var isOpenGraph = false
            if components.first == "og" {
                isOpenGraph = true
                components.removeFirst()
            }

            guard let content = try? metaTag.attr("content") else {
                continue
            }
            let name = String(components.removeFirst())
            var property = preview.properties[name, default: .init(name: name)]

            // Ignore redundant values, but treat OpenGraph data as authoritative.
            if components.isEmpty {
                if property.content == nil || isOpenGraph {
                    property.content = content
                }
            } else {
                let metadataName = String(components.removeFirst())
                if property.metadata[metadataName] == nil  || isOpenGraph {
                    property.metadata[metadataName] = content
                }
            }

            preview.properties[name] = property
        }
    }
}
