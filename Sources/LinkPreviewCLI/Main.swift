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
        guard var components = URLComponents(string: url) else {
            throw Error.invalidURL
        }
        if components.scheme == nil {
            components.scheme = "https"
        }
        guard let url = components.url else {
            throw Error.invalidURL
        }

        let provider = LinkPreviewProvider()
        let preview = try await provider.load(from: url)
        print(preview.debugDescription)
    }
}
