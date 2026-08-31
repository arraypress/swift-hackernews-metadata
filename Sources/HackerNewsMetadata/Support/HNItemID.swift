//
//  HNItemID.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Extracts a Hacker News item ID from raw IDs or item URLs.
///
/// Supported inputs:
/// - Raw numeric IDs (e.g., `"48854168"`)
/// - `https://news.ycombinator.com/item?id=48854168`
/// - `https://hn.algolia.com/api/v1/items/48854168`
/// - Any URL carrying an `id=<number>` query for `item`
public enum HNItemID {

    /// Extracts a numeric Hacker News item ID.
    ///
    /// - Parameter input: A raw ID or a Hacker News item URL.
    /// - Throws: ``HackerNewsMetadataError/invalidItemID`` if none can be found.
    /// - Returns: The item ID as a string of digits.
    public static func extract(from input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Raw numeric ID
        if trimmed.range(of: "^[0-9]+$", options: .regularExpression) != nil {
            return trimmed
        }

        // `item?id=<n>` or any `id=<n>` query parameter
        if let id = firstMatch(#"[?&]id=([0-9]+)"#, in: trimmed) {
            return id
        }

        // `.../items/<n>` (Algolia)
        if let id = firstMatch(#"/items/([0-9]+)"#, in: trimmed) {
            return id
        }

        throw HackerNewsMetadataError.invalidItemID
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
