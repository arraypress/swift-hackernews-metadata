//
//  HNStory+Derived.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//
//  The story's one derived fact.
//

import Foundation

extension HNStory {

    /// The canonical Hacker News URL for this item.
    public var hnURL: String {
        "https://news.ycombinator.com/item?id=\(id)"
    }
}
