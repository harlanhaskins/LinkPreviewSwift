//
//  LinkPreviewTests.swift
//  LinkPreview
//
//  Created by Harlan Haskins on 1/19/25.
//

import Foundation
import LinkPreview
import Testing

@Suite
struct LinkPreviewTests {
    let provider = LinkPreviewProvider()

    @Test func simpleFile() async throws {
        let preview = try await provider.load(from: URL(string: "https://apple.com")!)
        #expect(preview.description != nil)
        #expect(preview.title != nil)
    }

    @Test func descriptionFallback() async throws {
        let preview = try await provider.load(html: """
        <head>
        <meta property="og:title" content="Title" />
        <meta name="description" content="Hello, world" />
        </head>
        """, url: URL(string: "https://example.com")!)
        #expect(preview.title == "Title")
        #expect(preview.description == "Hello, world")
    }

    @Test func titleFallback() async throws {
        let preview = try await provider.load(html: """
        <head>
        <title>Title</title>
        <meta name="description" content="Hello, world" />
        </head>
        """, url: URL(string: "https://example.com")!)
        #expect(preview.title == "Title")
        #expect(preview.description == "Hello, world")
    }

    @Test func dropbox() async throws {
        let preview = try await provider.load(from: URL(string: "https://www.dropbox.com/scl/fi/9zhr8oqh8d49vgkvtn6jo/IMG_3996.HEIC?rlkey=iw62xieb2yrxtn0ujczl2lmkb&st=yq524xne&dl=0")!)
        #expect(preview.description != nil)
    }

    @Test func wikipedia() async throws {
        let url = URL(string: "https://en.wikipedia.org/wiki/Italian_language")!
        let preview = try await provider.load(from: url)
        #expect(preview.description != nil)
    }
}
