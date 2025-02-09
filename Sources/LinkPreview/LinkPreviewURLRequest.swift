//
//  File.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/9/25.
//

import Foundation
import AsyncHTTPClient

struct LinkPreviewURLRequest {
    var request: HTTPClientRequest

    var url: URL? {
        URL(string: request.url)
    }

    init(url: URL) {
        self.request = .init(url: url.absoluteString)
    }

    mutating func setValue(_ value: String, forHTTPHeaderField field: String) {
        if !request.headers.contains(name: field) {
            request.headers.add(name: field, value: value)
        }
    }

    func load() async throws -> Data {
        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(30))
        if response.status == .ok {
            let contentType = response.headers["Content-Type"]
            let isHTML = contentType.contains { $0.localizedCaseInsensitiveContains("text/html")
            }
            guard isHTML else {
                let contentTypeString = contentType.joined(separator: ", ")
                throw LinkPreviewError.unableToHandleContentType(contentTypeString, response)
            }
            let body = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
            return Data(body.readableBytesView)
        } else {
            // handle remote error
            throw LinkPreviewError.unsuccessfulHTTPStatus(Int(response.status.code), response)
        }
    }
}
