//
//  HNParser.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Hacker News' Algolia `items/{id}` response into a story and its
/// nested comment tree.
///
/// The response is a single item whose `children` array recursively contains
/// the full comment tree, so one request yields everything.
enum HNParser {

    /// Parses an Algolia item response into a story and its comment tree.
    ///
    /// - Parameter data: The raw JSON from `hn.algolia.com/api/v1/items/{id}`.
    /// - Throws: ``HackerNewsMetadataError/parsingError(_:)`` if malformed.
    /// - Returns: The story metadata and its top-level comments (with replies).
    static func parse(data: Data) throws -> (story: HNStory, comments: [HNComment]) {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HackerNewsMetadataError.parsingError("Invalid Hacker News JSON")
        }

        let comments = parseChildren(root["children"], depth: 0)
        let bodyHTML = root["text"] as? String

        let story = HNStory(
            id: root["id"] as? Int ?? 0,
            type: root["type"] as? String ?? "story",
            title: root["title"] as? String,
            url: root["url"] as? String,
            author: root["author"] as? String,
            text: bodyHTML.map(HNHTML.toPlainText),
            points: root["points"] as? Int,
            createdAt: date(from: root),
            commentCount: comments.totalCount
        )

        return (story, comments)
    }

    // MARK: - Comments

    private static func parseChildren(_ value: Any?, depth: Int) -> [HNComment] {
        guard let nodes = value as? [[String: Any]] else { return [] }
        return nodes.map { parseNode($0, depth: depth) }
    }

    private static func parseNode(_ node: [String: Any], depth: Int) -> HNComment {
        let bodyHTML = node["text"] as? String
        return HNComment(
            id: node["id"] as? Int ?? 0,
            author: node["author"] as? String,
            text: bodyHTML.map(HNHTML.toPlainText),
            textHTML: bodyHTML,
            createdAt: date(from: node),
            parentId: node["parent_id"] as? Int,
            storyId: node["story_id"] as? Int,
            depth: depth,
            children: parseChildren(node["children"], depth: depth + 1)
        )
    }

    // MARK: - Helpers

    /// Reads the `created_at_i` UNIX timestamp into a `Date`.
    private static func date(from node: [String: Any]) -> Date? {
        guard let seconds = node["created_at_i"] as? Int else { return nil }
        return Date(timeIntervalSince1970: Double(seconds))
    }
}
