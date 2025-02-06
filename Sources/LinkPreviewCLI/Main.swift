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

        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: url)
        print(preview.debugDescription)
    }
}
