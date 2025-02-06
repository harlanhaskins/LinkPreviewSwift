//
//  MetadataProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
public import SwiftSoup

public struct MetadataProcessingOptions: Sendable {
    public var allowAdditionalRequests: Bool = true
}

public protocol MetadataProcessor {
    static func applies(to url: URL) -> Bool
    static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document,
        in session: URLSession,
        options: MetadataProcessingOptions
    ) async
}
