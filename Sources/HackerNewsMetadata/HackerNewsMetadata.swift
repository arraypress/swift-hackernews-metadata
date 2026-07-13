//
//  HackerNewsMetadata.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetch Hacker News stories and their full comment trees without authentication.
///
/// Uses Hacker News' public Algolia API (`hn.algolia.com/api/v1`), which returns
/// an entire thread — story metadata plus every nested comment — in a single
/// request. No API key or login required.
///
/// ## Quick Start
///
/// ```swift
/// import HackerNewsMetadata
///
/// // Story + full comment tree in one call
/// let (story, comments) = try await HackerNewsMetadata.fetchWithComments(
///     "https://news.ycombinator.com/item?id=48854168"
/// )
///
/// print(story.title ?? "")
/// print("\(story.points ?? 0) points · \(comments.totalCount) comments")
///
/// for c in comments.flattened {
///     let indent = String(repeating: "  ", count: c.depth)
///     print("\(indent)\(c.author ?? "[deleted]"): \(c.text ?? "")")
/// }
/// ```
///
/// ## Supported Inputs
///
/// - Raw item IDs (e.g., `"48854168"`)
/// - `https://news.ycombinator.com/item?id=48854168`
/// - `https://hn.algolia.com/api/v1/items/48854168`
public enum HackerNewsMetadata {

    // MARK: - Configuration

    /// The base URL for Hacker News' public Algolia API.
    private static let algoliaBase = "https://hn.algolia.com/api/v1"

    /// The User-Agent header sent with all requests.
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"

    // MARK: - Public API

    /// Fetches a story's metadata **and** its full comment tree in one request.
    ///
    /// - Parameter input: A Hacker News item ID or URL.
    /// - Throws: ``HackerNewsMetadataError`` if the item is invalid or the
    ///   response cannot be retrieved or parsed.
    /// - Returns: The story and its top-level comments (each with nested replies).
    public static func fetchWithComments(
        _ input: String
    ) async throws -> (story: HNStory, comments: [HNComment]) {
        let id = try HNItemID.extract(from: input)
        let data = try await fetchItem(id: id)
        return try HNParser.parse(data: data)
    }

    /// Fetches a story's full comment tree.
    ///
    /// Comments nest via ``HNComment/children``; use
    /// ``HNComment/flattened`` (or the array's `flattened`) for a depth-first list.
    ///
    /// - Parameter input: A Hacker News item ID or URL.
    /// - Returns: The top-level comments, each carrying its nested replies.
    public static func comments(_ input: String) async throws -> [HNComment] {
        try await fetchWithComments(input).comments
    }

    /// Fetches a Hacker News item's top-level metadata.
    ///
    /// - Parameter input: A Hacker News item ID or URL.
    /// - Returns: The ``HNStory`` metadata (title, author, points, comment count…).
    public static func story(_ input: String) async throws -> HNStory {
        try await fetchWithComments(input).story
    }

    /// Full-text searches Hacker News stories and comments.
    ///
    /// Powered by Hacker News' public Algolia search. Combine a type filter, an
    /// author, minimum points/comments, and a date range; page through results
    /// with ``HNSearchResults/hasNextPage`` and ``HNSearchResults/pageCount``.
    ///
    /// Each hit's ``HNSearchHit/id`` (or ``HNSearchHit/storyId`` for comment
    /// hits) can be passed straight to ``fetchWithComments(_:)``.
    ///
    /// ```swift
    /// let results = try await HackerNewsMetadata.search(
    ///     "swift concurrency", in: .stories, sortBy: .relevance, minPoints: 50
    /// )
    /// print("\(results.totalHits) matches")
    /// for hit in results.hits {
    ///     print("\(hit.title ?? "") — \(hit.points ?? 0) pts")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - query: The full-text query.
    ///   - tag: Restrict to a type (stories, comments, Ask HN…). Defaults to ``HNSearchTag/all``.
    ///   - sortBy: Relevance or newest-first. Defaults to ``HNSearchSort/relevance``.
    ///   - minPoints: Only items with at least this many points.
    ///   - minComments: Only stories with at least this many comments.
    ///   - author: Only items by this username.
    ///   - storyId: Only comments belonging to this story.
    ///   - createdAfter: Only items created at or after this date.
    ///   - createdBefore: Only items created at or before this date.
    ///   - page: Zero-based page index.
    ///   - hitsPerPage: Results per page (Algolia caps this at 1000).
    /// - Returns: A page of ``HNSearchResults``.
    public static func search(
        _ query: String,
        in tag: HNSearchTag = .all,
        sortBy: HNSearchSort = .relevance,
        minPoints: Int? = nil,
        minComments: Int? = nil,
        author: String? = nil,
        storyId: Int? = nil,
        createdAfter: Date? = nil,
        createdBefore: Date? = nil,
        page: Int = 0,
        hitsPerPage: Int = 20
    ) async throws -> HNSearchResults {
        guard var components = URLComponents(string: "\(algoliaBase)/\(sortBy.endpoint)") else {
            throw HackerNewsMetadataError.parsingError("Invalid search URL")
        }

        var items: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "hitsPerPage", value: String(hitsPerPage))
        ]

        // `tags` are AND-combined (comma-separated).
        var tagParts: [String] = []
        if let tagValue = tag.tagValue { tagParts.append(tagValue) }
        if let author { tagParts.append("author_\(author)") }
        if let storyId { tagParts.append("story_\(storyId)") }
        if !tagParts.isEmpty {
            items.append(URLQueryItem(name: "tags", value: tagParts.joined(separator: ",")))
        }

        var numericFilters: [String] = []
        if let minPoints { numericFilters.append("points>=\(minPoints)") }
        if let minComments { numericFilters.append("num_comments>=\(minComments)") }
        if let createdAfter { numericFilters.append("created_at_i>=\(Int(createdAfter.timeIntervalSince1970))") }
        if let createdBefore { numericFilters.append("created_at_i<=\(Int(createdBefore.timeIntervalSince1970))") }
        if !numericFilters.isEmpty {
            items.append(URLQueryItem(name: "numericFilters", value: numericFilters.joined(separator: ",")))
        }

        components.queryItems = items
        guard let url = components.url else {
            throw HackerNewsMetadataError.parsingError("Invalid search URL")
        }

        let data = try await perform(url)
        return try HNSearchParser.parse(data: data, query: query)
    }

    // MARK: - Networking

    private static func fetchItem(id: String) async throws -> Data {
        guard let url = URL(string: "\(algoliaBase)/items/\(id)") else {
            throw HackerNewsMetadataError.invalidItemID
        }
        return try await perform(url)
    }

    /// Performs a GET against the Algolia API and maps status codes to errors.
    private static func perform(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw HackerNewsMetadataError.networkError(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 { throw HackerNewsMetadataError.itemNotFound }
            if httpResponse.statusCode == 429 { throw HackerNewsMetadataError.rateLimited }
            if httpResponse.statusCode != 200 {
                throw HackerNewsMetadataError.networkError("HTTP \(httpResponse.statusCode)")
            }
        }

        return data
    }
}
