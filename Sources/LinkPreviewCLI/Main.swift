//
//  Main.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

import ArgumentParser
import Foundation
import LinkPreview

@main
struct LinkPreviewCLI: AsyncParsableCommand {
    enum Error: Swift.Error {
        case invalidURL
    }
    @Argument(help: "The URL to print metadata for")
    var url: String

    mutating func run() async throws {
        var urlString = url
        if !urlString.hasPrefix("http") {
            urlString = "https://\(urlString)"
        }
        guard let url = URL(string: urlString) else {
            throw Error.invalidURL
        }

        // ajs_anonymous_id ec4a86d0-2fa4-4507-990c-4ed91706fdef
        // ajs_user_id 06b6f33bc5e2fd2a639ec0b9975687705cc82f498db1354b1b3de339e9c89aec
        // AWSALB +4ecmBSASYzAh9b0dB6rUjmWxpnGy22P1IhFtSZNh296Jt+Eurhc2pmgrm1XgcBb8l6YPNAo6OXxEPgnXham94CdTr7KkMRw58mkWh2PerG5pD6Yy/HZcXcsVVrJ
        // AWSALBCORS +4ecmBSASYzAh9b0dB6rUjmWxpnGy22P1IhFtSZNh296Jt+Eurhc2pmgrm1XgcBb8l6YPNAo6OXxEPgnXham94CdTr7KkMRw58mkWh2PerG5pD6Yy/HZcXcsVVrJ

        let provider = LinkPreviewProvider()
        provider.options.websiteSpecificUserAgents = [
            WebsiteSpecificUserAgent(
                hostname: "bsky.app",
                userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
            )
        ]

        let preview = try await provider.load(from: url, headers: ["Cookie" : "ajs_anonymous_id=ec4a86d0-2fa4-4507-990c-4ed91706fdef; ajs_user_id=06b6f33bc5e2fd2a639ec0b9975687705cc82f498db1354b1b3de339e9c89aec; AWSALB=+4ecmBSASYzAh9b0dB6rUjmWxpnGy22P1IhFtSZNh296Jt+Eurhc2pmgrm1XgcBb8l6YPNAo6OXxEPgnXham94CdTr7KkMRw58mkWh2PerG5pD6Yy/HZcXcsVVrJ; AWSALBCORS=+4ecmBSASYzAh9b0dB6rUjmWxpnGy22P1IhFtSZNh296Jt+Eurhc2pmgrm1XgcBb8l6YPNAo6OXxEPgnXham94CdTr7KkMRw58mkWh2PerG5pD6Yy/HZcXcsVVrJ"])

//        let provider = LinkPreviewProvider(processors: [WikipediaAPIProcessor.self])
//        let preview = try await provider.load(from: url)
        print(preview.debugDescription)
    }
}
