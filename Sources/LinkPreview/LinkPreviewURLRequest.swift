//
//  File.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/9/25.
//

import Foundation
import AsyncHTTPClient

struct LinkPreviewURLRequest {
    enum Output {
        case html(Data)
        case fileURL(URL, String)
    }
    var request: HTTPClientRequest
    let url: URL

    init(url: URL) {
        self.url = url
        self.request = .init(url: url.absoluteString)
    }

    mutating func setValue(_ value: String, forHTTPHeaderField field: String) {
        if !request.headers.contains(name: field) {
            request.headers.add(name: field, value: value)
        }
    }

    func load() async throws -> Output {
        let response = try await HTTPClient.shared.execute(request, timeout: .seconds(5))
        guard response.status == .ok else {
            throw LinkPreviewError.unsuccessfulHTTPStatus(Int(response.status.code), response)
        }

        let contentTypes = response.headers["Content-Type"]
        for contentType in contentTypes {
            let isHTML = contentType.localizedCaseInsensitiveContains("text/html")

            if isHTML {
                let body = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
                return .html(Data(body.readableBytesView))
            }

            return .fileURL(url, contentType)
        }

        let contentTypeString = contentTypes.joined(separator: ", ")
        throw LinkPreviewError.unableToHandleContentType(contentTypeString, response)
    }
}
