//
//  HNSearchResults.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A page of Hacker News search results, with pagination metadata.
///
/// ```swift
/// var page = 0
/// repeat {
///     let results = try await HackerNewsMetadata.search("llm", in: .stories, page: page)
///     process(results.hits)
///     page += 1
/// } while page < results.pageCount
/// ```
public struct HNSearchResults: Sendable {

    /// The hits on this page.
    public let hits: [HNSearchHit]

    /// The query that produced these results.
    public let query: String

    /// The zero-based index of this page.
    public let page: Int

    /// The total number of pages available.
    public let pageCount: Int

    /// The total number of matching items across all pages.
    public let totalHits: Int

    /// The number of hits requested per page.
    public let hitsPerPage: Int

    /// Whether another page of results is available after this one.
    public var hasNextPage: Bool { page + 1 < pageCount }

    /// Creates a page of search results.
    public init(
        hits: [HNSearchHit],
        query: String,
        page: Int,
        pageCount: Int,
        totalHits: Int,
        hitsPerPage: Int
    ) {
        self.hits = hits
        self.query = query
        self.page = page
        self.pageCount = pageCount
        self.totalHits = totalHits
        self.hitsPerPage = hitsPerPage
    }
}
