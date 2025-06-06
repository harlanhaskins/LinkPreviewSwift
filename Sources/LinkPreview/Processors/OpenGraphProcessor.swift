//
//  OpenGraphProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

import Foundation
import SwiftSoup

public enum OpenGraphProcessor: MetadataProcessor {
    public static var activationRule: MetadataProcessorActivationRule {
        .always
    }

    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document?,
        options: MetadataProcessingOptions
    ) async {
        guard let document else {
            return
        }
        let metaTags = try? document.select("meta")
        for metaTag in metaTags?.array() ?? [] {
            let propertyTag = try? metaTag.attr("property")
            let nameTag = try? metaTag.attr("name")
            guard let propertyNameTag = propertyTag?.nonEmpty ?? nameTag else {
                continue
            }
            var components = propertyNameTag.split(separator: ":")
            if components.count < 2 { continue }

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

extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
