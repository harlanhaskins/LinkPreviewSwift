//
//  WikipediaParser.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 2/5/25.
//

public import SwiftSoup
public import Foundation

public enum WikipediaAPIProcessor: MetadataProcessor {
    public static func applies(to url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        return host.hasSuffix("wikipedia.org")
    }

    public static func updateLinkPreview(
        _ preview: inout LinkPreview,
        for url: URL,
        document: Document,
        in session: URLSession,
        options: MetadataProcessingOptions
    ) async {
        // Skip if the client requested no new requests.
        if !options.allowAdditionalRequests {
            return
        }

        // No need to fetch a new description if there's one there.
        if preview.description != nil {
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
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200..<299).contains(httpResponse.statusCode) else {
                return
            }

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
