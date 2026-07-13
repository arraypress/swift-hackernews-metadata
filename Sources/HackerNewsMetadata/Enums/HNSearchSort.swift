//
//  HNSearchSort.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// How Hacker News search results are ordered.
public enum HNSearchSort: Sendable {

    /// Relevance-ranked (Algolia `search` endpoint).
    case relevance

    /// Newest first (Algolia `search_by_date` endpoint).
    case date

    /// The Algolia endpoint path for this ordering.
    var endpoint: String {
        switch self {
        case .relevance: return "search"
        case .date: return "search_by_date"
        }
    }
}
