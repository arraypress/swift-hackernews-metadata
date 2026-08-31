//
//  SupportTests.swift
//  HackerNewsMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The ID parser pinned directly.
//

import XCTest
@testable import HackerNewsMetadata

final class SupportTests: XCTestCase {

    func testItemIDParserEdges() throws {
        XCTAssertEqual(try HNItemID.extract(from: "48854168"), "48854168")
        XCTAssertEqual(try HNItemID.extract(from: "https://news.ycombinator.com/item?id=48854168&p=2"), "48854168")
        XCTAssertEqual(try HNItemID.extract(from: "https://hn.algolia.com/api/v1/items/48854168"), "48854168")
        XCTAssertThrowsError(try HNItemID.extract(from: "https://news.ycombinator.com/newest"))
    }
}
