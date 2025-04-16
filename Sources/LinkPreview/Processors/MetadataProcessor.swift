//
//  MetadataProcessor.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

import Foundation
import SwiftSoup

public struct MetadataProcessingOptions: Sendable {
    public var allowAdditionalRequests: Bool = true
	public var websiteSpecificUserAgents: [WebsiteSpecificUserAgent]
	public var requestTimeout: Int64 = 10

    public init() {
        self.websiteSpecificUserAgents = [WebsiteSpecificUserAgent(
            hostname: "spotify.com",
            userAgent: "Twitterbot/1.0"
        )]
    }
}

public protocol MetadataProcessor {
    static var activationRule: MetadataProcessorActivationRule { get }

    static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document?,
        options: MetadataProcessingOptions
    ) async
}
