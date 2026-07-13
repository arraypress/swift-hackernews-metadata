//
//  HackerNewsMetadataTests.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import HackerNewsMetadata

final class HackerNewsMetadataTests: XCTestCase {

    // MARK: - Item ID extraction

    func testExtractRawID() throws {
        XCTAssertEqual(try HNItemID.extract(from: "48854168"), "48854168")
    }

    func testExtractFromItemURL() throws {
        XCTAssertEqual(
            try HNItemID.extract(from: "https://news.ycombinator.com/item?id=48854168"),
            "48854168"
        )
    }

    func testExtractFromURLWithExtraParams() throws {
        XCTAssertEqual(
            try HNItemID.extract(from: "https://news.ycombinator.com/item?goto=x&id=99&y=1"),
            "99"
        )
    }

    func testExtractFromAlgoliaURL() throws {
        XCTAssertEqual(
            try HNItemID.extract(from: "https://hn.algolia.com/api/v1/items/123"),
            "123"
        )
    }

    func testExtractInvalidThrows() {
        XCTAssertThrowsError(try HNItemID.extract(from: "not-an-id"))
    }

    // MARK: - HTML decoding

    func testHTMLToPlainText() {
        let html = "First &amp; best<p>a <a href=\"https://x.com\">link</a> and &#x27;quotes&#x27;"
        XCTAssertEqual(HNHTML.toPlainText(html), "First & best\n\na link and 'quotes'")
    }

    func testHTMLNumericEntities() {
        XCTAssertEqual(HNHTML.unescape("a &#38; b &#x2764; c"), "a & b ❤ c")
    }

    // MARK: - Tree parsing

    func testParseStoryAndComments() throws {
        let (story, comments) = try HNParser.parse(data: Data(Fixture.thread.utf8))

        XCTAssertEqual(story.id, 100)
        XCTAssertEqual(story.type, "story")
        XCTAssertEqual(story.title, "Test story")
        XCTAssertEqual(story.author, "pg")
        XCTAssertEqual(story.points, 42)
        XCTAssertEqual(story.commentCount, 3)
        XCTAssertNotNil(story.createdAt)

        XCTAssertEqual(comments.count, 2)

        let top = comments[0]
        XCTAssertEqual(top.id, 101)
        XCTAssertEqual(top.author, "alice")
        XCTAssertEqual(top.depth, 0)
        XCTAssertEqual(top.parentId, 100)
        XCTAssertEqual(top.storyId, 100)
        XCTAssertEqual(top.text, "First & best comment\n\nSecond paragraph with a link and 'quotes'")
        XCTAssertEqual(top.textHTML?.contains("&amp;"), true)
        XCTAssertEqual(top.children.count, 1)

        let reply = top.children[0]
        XCTAssertEqual(reply.id, 102)
        XCTAssertEqual(reply.depth, 1)
        XCTAssertEqual(reply.parentId, 101)
    }

    func testDeletedComment() throws {
        let (_, comments) = try HNParser.parse(data: Data(Fixture.thread.utf8))
        let deleted = comments[1]
        XCTAssertEqual(deleted.id, 103)
        XCTAssertNil(deleted.author)
        XCTAssertNil(deleted.text)
        XCTAssertTrue(deleted.isDeleted)
    }

    func testFlattenAndCounts() throws {
        let (_, comments) = try HNParser.parse(data: Data(Fixture.thread.utf8))
        XCTAssertEqual(comments.flattened.map(\.id), [101, 102, 103])
        XCTAssertEqual(comments.totalCount, 3)
        XCTAssertEqual(comments[0].replyCount, 1)
    }

    // MARK: - Search parsing

    func testParseSearchResults() throws {
        let results = try HNSearchParser.parse(data: Data(Fixture.search.utf8), query: "rust")

        XCTAssertEqual(results.totalHits, 103)
        XCTAssertEqual(results.page, 0)
        XCTAssertEqual(results.pageCount, 35)
        XCTAssertTrue(results.hasNextPage)
        XCTAssertEqual(results.hits.count, 2)

        let story = results.hits[0]
        XCTAssertEqual(story.id, 13663751)
        XCTAssertEqual(story.type, "story")
        XCTAssertTrue(story.isStory)
        XCTAssertEqual(story.title, "The Rust Programming Language")
        XCTAssertEqual(story.author, "nanxor")
        XCTAssertEqual(story.points, 346)
        XCTAssertEqual(story.commentCount, 108)

        let comment = results.hits[1]
        XCTAssertEqual(comment.id, 48879142)
        XCTAssertTrue(comment.isComment)
        XCTAssertEqual(comment.storyId, 48849744)
        XCTAssertEqual(comment.storyTitle, "Some Story")
        XCTAssertEqual(comment.parentId, 48878997)
        XCTAssertEqual(comment.text, "A comment about rust & things")   // HTML decoded
    }

    // MARK: - Live network test (opt-in)

    func testLiveFetch() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["HN_LIVE_TESTS"] == "1",
            "Set HN_LIVE_TESTS=1 to run live network tests."
        )
        // Item 8863 — the 2007 Dropbox "Show HN" launch, hundreds of comments.
        let (story, comments) = try await HackerNewsMetadata.fetchWithComments(
            "https://news.ycombinator.com/item?id=8863"
        )
        XCTAssertEqual(story.id, 8863)
        XCTAssertNotNil(story.title)
        XCTAssertFalse(comments.isEmpty)
        XCTAssertTrue(comments.flattened.contains { !($0.text ?? "").isEmpty })

        if ProcessInfo.processInfo.environment["HN_PRINT"] == "1" {
            print("=== \(story.title ?? "") — \(story.points ?? 0) pts, \(comments.totalCount) comments ===")
            for c in comments.flattened.prefix(6) {
                let indent = String(repeating: "  ", count: c.depth)
                print("\(indent)\(c.author ?? "[deleted]"): \((c.text ?? "").prefix(90))")
            }
        }
    }

    func testLiveSearch() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["HN_LIVE_TESTS"] == "1",
            "Set HN_LIVE_TESTS=1 to run live network tests."
        )
        let results = try await HackerNewsMetadata.search(
            "rust", in: .stories, sortBy: .relevance, minPoints: 100, hitsPerPage: 5
        )
        XCTAssertGreaterThan(results.totalHits, 0)
        XCTAssertFalse(results.hits.isEmpty)
        XCTAssertTrue(results.hits.allSatisfy { ($0.points ?? 0) >= 100 })
        XCTAssertTrue(results.hits.allSatisfy(\.isStory))

        if ProcessInfo.processInfo.environment["HN_PRINT"] == "1" {
            print("=== search 'rust' (stories, >=100 pts): \(results.totalHits) matches ===")
            for h in results.hits {
                print("• \(h.title ?? "") — \(h.points ?? 0) pts, \(h.commentCount) comments  [\(h.author ?? "?")]")
            }
        }
    }
}

// MARK: - Fixture

/// A structurally faithful Algolia `items/{id}` response.
private enum Fixture {
    static let thread = """
    {
      "id": 100, "type": "story", "author": "pg", "title": "Test story",
      "url": "https://example.com", "points": 42, "text": null,
      "created_at_i": 1700000000, "parent_id": null, "story_id": 100,
      "children": [
        { "id": 101, "type": "comment", "author": "alice",
          "text": "First &amp; best comment<p>Second paragraph with a <a href=\\"https://x.com\\">link</a> and &#x27;quotes&#x27;",
          "points": null, "parent_id": 100, "story_id": 100, "created_at_i": 1700000100,
          "children": [
            { "id": 102, "type": "comment", "author": "bob", "text": "A reply",
              "parent_id": 101, "story_id": 100, "created_at_i": 1700000200, "children": [] }
          ] },
        { "id": 103, "type": "comment", "author": null, "text": null,
          "parent_id": 100, "story_id": 100, "created_at_i": 1700000300, "children": [] }
      ]
    }
    """

    static let search = """
    {
      "hits": [
        { "objectID": "13663751", "title": "The Rust Programming Language",
          "url": "https://rust-lang.github.io/book/", "author": "nanxor",
          "points": 346, "num_comments": 108, "created_at_i": 1487280867,
          "story_text": null, "_tags": ["story", "author_nanxor", "story_13663751"] },
        { "objectID": "48879142", "author": "aesthesia",
          "comment_text": "A comment about rust &amp; things",
          "story_id": 48849744, "story_title": "Some Story", "parent_id": 48878997,
          "created_at_i": 1783841545, "_tags": ["comment", "author_aesthesia", "story_48849744"] }
      ],
      "nbHits": 103, "page": 0, "nbPages": 35, "hitsPerPage": 2, "query": "rust"
    }
    """
}
