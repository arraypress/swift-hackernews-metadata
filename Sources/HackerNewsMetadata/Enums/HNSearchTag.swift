//
//  HNSearchTag.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The kind of Hacker News item to restrict a search to.
///
/// Maps to Algolia's `tags` filter.
public enum HNSearchTag: Sendable {

    /// No type restriction (stories, comments, polls…).
    case all

    /// Stories only.
    case stories

    /// Comments only.
    case comments

    /// "Ask HN" stories.
    case askHN

    /// "Show HN" stories.
    case showHN

    /// Polls.
    case polls

    /// Items currently on the front page.
    case frontPage

    /// The Algolia tag value, or `nil` for ``all``.
    var tagValue: String? {
        switch self {
        case .all: return nil
        case .stories: return "story"
        case .comments: return "comment"
        case .askHN: return "ask_hn"
        case .showHN: return "show_hn"
        case .polls: return "poll"
        case .frontPage: return "front_page"
        }
    }
}
