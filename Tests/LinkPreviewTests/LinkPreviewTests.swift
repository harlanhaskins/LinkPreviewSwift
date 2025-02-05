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
    @Test func testSimpleFile() async throws {
        let preview = try await LinkPreview.load(from: URL(string: "https://apple.com")!)
        #expect(preview.description != nil)
        #expect(preview.title != nil)
    }

    @Test func testDescriptionFallback() throws {
        let preview = try LinkPreview(html: """
        <head>
        <meta property="og:title" content="Title" />
        <meta name="description" content="Hello, world" />
        </head>
        """, url: URL(string: "https://example.com")!)
        #expect(preview.title == "Title")
        #expect(preview.openGraph[.title] == "Title")
        #expect(preview.openGraph[.description] == nil)
        #expect(preview.description == "Hello, world")
    }

    @Test func testTitleFallback() throws {
        let preview = try LinkPreview(html: """
        <head>
        <title>Title</title>
        <meta name="description" content="Hello, world" />
        </head>
        """, url: URL(string: "https://example.com")!)
        #expect(preview.title == "Title")
        #expect(preview.openGraph[.title] == nil)
        #expect(preview.openGraph[.description] == nil)
        #expect(preview.description == "Hello, world")
    }

    @Test func testDropbox() async throws {
        let preview = try await LinkPreview.load(from: URL(string: "https://www.dropbox.com/scl/fi/9zhr8oqh8d49vgkvtn6jo/IMG_3996.HEIC?rlkey=iw62xieb2yrxtn0ujczl2lmkb&st=yq524xne&dl=0")!)
        #expect(preview.description != nil)
    }
}
