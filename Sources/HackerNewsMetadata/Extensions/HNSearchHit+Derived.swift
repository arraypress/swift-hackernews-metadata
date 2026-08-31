//
//  HNSearchHit+Derived.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//
//  The hit's derived facts, stated in full — each is a one-liner.
//

import Foundation

extension HNSearchHit {

    /// Whether this hit is a comment.
    public var isComment: Bool { type == "comment" }

    /// Whether this hit is a story.
    public var isStory: Bool { type == "story" }

    /// The canonical Hacker News URL for this item.
    public var hnURL: String {
        "https://news.ycombinator.com/item?id=\(id)"
    }
}
