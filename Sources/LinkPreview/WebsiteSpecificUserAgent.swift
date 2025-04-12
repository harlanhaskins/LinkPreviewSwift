//
//  WebsiteSpecificUserAgent.swift
//  LinkPreview
//
//  Created by Joe Fabisevich on 4/11/25.
//

public struct WebsiteSpecificUserAgent: Sendable {
    let hostname: String
    let userAgent: String

    public init(hostname: String, userAgent: String) {
        self.hostname = hostname
        self.userAgent = userAgent
    }
}
