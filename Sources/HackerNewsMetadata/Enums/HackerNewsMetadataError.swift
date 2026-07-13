//
//  HackerNewsMetadataError.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when fetching Hacker News items and comments.
///
/// ```swift
/// do {
///     let comments = try await HackerNewsMetadata.comments("48854168")
/// } catch HackerNewsMetadataError.itemNotFound {
///     print("No such item")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum HackerNewsMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The provided string is not a valid Hacker News item URL or ID.
    case invalidItemID

    /// The item does not exist (or has no data).
    case itemNotFound

    /// Hacker News / Algolia is rate-limiting requests from this IP.
    case rateLimited

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response data.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidItemID:
            return "Invalid Hacker News item. Provide an item ID (e.g., \"48854168\") or a news.ycombinator.com/item?id=… URL."
        case .itemNotFound:
            return "Hacker News item not found."
        case .rateLimited:
            return "Hacker News is rate-limiting requests. Try again later."
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
