//
//  HNComment+Tree.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//
//  The comment tree's derived facts — flattening, counting, deletion —
//  kept out of the model file so the shape reads alone.
//

import Foundation

extension HNComment {

    /// Whether the comment has been deleted or removed.
    public var isDeleted: Bool { author == nil || text == nil }

    /// Whether this comment has any replies.
    public var hasReplies: Bool { !children.isEmpty }

    /// The total number of descendant comments beneath this one.
    public var replyCount: Int {
        children.reduce(children.count) { $0 + $1.replyCount }
    }

    /// This comment followed by every descendant, depth-first.
    ///
    /// - Important: The result **includes the comment it is called on**, so a
    ///   whole thread flattens with `roots.flatMap(\.flattened)`. Writing
    ///   `roots.flatMap { [$0] + $0.flattened }` duplicates every root.
    public var flattened: [HNComment] {
        [self] + children.flatMap(\.flattened)
    }
}

// MARK: - Array helpers

public extension Array where Element == HNComment {

    /// All comments in the tree, depth-first (each comment followed by its replies).
    var flattened: [HNComment] {
        flatMap(\.flattened)
    }

    /// The total number of comments in the tree (top-level + all replies).
    var totalCount: Int {
        reduce(count) { $0 + $1.replyCount }
    }
}
