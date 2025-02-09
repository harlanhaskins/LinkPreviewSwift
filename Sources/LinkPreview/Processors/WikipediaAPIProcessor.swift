//
//  WikipediaParser.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

import AsyncHTTPClient
public import Foundation
public import SwiftSoup

/// A Wikipedia-specific processor that hits the Wikipedia API in order to
/// extract text from the articles.
public enum WikipediaAPIProcessor: MetadataProcessor {
    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document?,
        options: MetadataProcessingOptions
    ) async {
        // Only apply this to Wikipedia.org URLs
        guard url.baseHostName == "wikipedia.org" else {
            return
        }

        guard let document else {
            return
        }

        // No need to fetch a new description if there's one there.
        if preview.description != nil {
            return
        }

        if let shortDescription = try? document.select("div.shortdescription"),
           let text = try? shortDescription.text(), !text.isEmpty {
            preview.description = text
            return
        }

        // Skip if the client requested no new requests.
        if !options.allowAdditionalRequests {
            return
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = url.host
        components.path = "/w/api.php"
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "titles", value: url.lastPathComponent),
            URLQueryItem(name: "exintro", value: nil),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "prop", value: "extracts"),
            URLQueryItem(name: "explaintext", value: nil)
        ]

        guard let url = components.url else {
            return
        }

        do {
            let request = HTTPClientRequest(url: url.absoluteString)
            let response = try await HTTPClient.shared.execute(request, timeout: .seconds(5))
            guard response.status == .ok else {
                return
            }

            let buffer = try await response.body.collect(upTo: 1024 * 1024) // 1 MB
            let data = Data(buffer.readableBytesView)
            let wikipediaResponse = try JSONSerialization.jsonObject(with: data)
            guard let dict = wikipediaResponse as? [String: Any],
                  let query = dict["query"] as? [String: Any],
                  let pages = query["pages"] as? [String: Any],
                  let (_, result) = pages.first,
                  let page = result as? [String: Any] else {
                return
            }

            if preview.title == nil, let title = page["title"] as? String {
                preview.title = title
            }

            if preview.description == nil, let extract = page["extract"] as? String {
                preview.description = extract
            }
        } catch {
            return
        }
    }

}
