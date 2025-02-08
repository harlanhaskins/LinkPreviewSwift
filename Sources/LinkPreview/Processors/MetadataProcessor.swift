//
//  MetadataProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import Foundation
#if canImport(FoundationNetworking)
public import FoundationNetworking
#endif
public import SwiftSoup

public struct MetadataProcessingOptions: Sendable {
    public var allowAdditionalRequests: Bool = true
    public init() {}
}

public protocol MetadataProcessor {
    static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document,
        in session: URLSession,
        options: MetadataProcessingOptions
    ) async
}
