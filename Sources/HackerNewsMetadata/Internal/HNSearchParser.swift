//
//  HNSearchParser.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Hacker News' Algolia `search` / `search_by_date` response into
/// ``HNSearchResults``.
enum HNSearchParser {

    /// Known Algolia item-type tags, in the order we prefer to detect them.
    private static let typeTags = ["story", "comment", "poll", "pollopt", "job"]

    /// Parses a search response.
    ///
    /// - Parameters:
    ///   - data: The raw JSON from `hn.algolia.com/api/v1/search[_by_date]`.
    ///   - query: The query used, as a fallback if the response omits it.
    /// - Throws: ``HackerNewsMetadataError/parsingError(_:)`` if malformed.
    static func parse(data: Data, query: String) throws -> HNSearchResults {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HackerNewsMetadataError.parsingError("Invalid Hacker News search JSON")
        }

        let hits = (root["hits"] as? [[String: Any]] ?? []).map(parseHit)

        return HNSearchResults(
            hits: hits,
            query: root["query"] as? String ?? query,
            page: root["page"] as? Int ?? 0,
            pageCount: root["nbPages"] as? Int ?? 0,
            totalHits: root["nbHits"] as? Int ?? hits.count,
            hitsPerPage: root["hitsPerPage"] as? Int ?? hits.count
        )
    }

    // MARK: - Hits

    private static func parseHit(_ hit: [String: Any]) -> HNSearchHit {
        let tags = hit["_tags"] as? [String] ?? []
        let type = tags.first(where: typeTags.contains)
            ?? (hit["title"] != nil ? "story" : "comment")

        // A hit carries either comment_text (comments) or story_text (Ask HN).
        let bodyHTML = (hit["comment_text"] as? String) ?? (hit["story_text"] as? String)

        return HNSearchHit(
            id: intValue(hit["objectID"]) ?? 0,
            type: type,
            author: hit["author"] as? String,
            title: hit["title"] as? String,
            url: hit["url"] as? String,
            points: hit["points"] as? Int,
            commentCount: hit["num_comments"] as? Int ?? 0,
            text: bodyHTML.map(HNHTML.toPlainText),
            createdAt: (hit["created_at_i"] as? Int).map { Date(timeIntervalSince1970: Double($0)) },
            storyId: intValue(hit["story_id"]),
            storyTitle: hit["story_title"] as? String,
            parentId: intValue(hit["parent_id"])
        )
    }

    /// Algolia returns `objectID` as a string but numeric IDs as numbers.
    private static func intValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let string = value as? String { return Int(string) }
        return nil
    }
}
