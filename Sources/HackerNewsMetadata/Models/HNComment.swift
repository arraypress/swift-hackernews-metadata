//
//  HNComment.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single Hacker News comment, with its nested replies.
///
/// Fetched from Hacker News' public Algolia API, which returns the entire
/// comment tree for a thread in one request. Each comment carries its
/// ``children``; use ``flattened`` for a depth-first list.
///
/// ```swift
/// let comments = try await HackerNewsMetadata.comments("48854168")
/// for c in comments.flattened {
///     let indent = String(repeating: "  ", count: c.depth)
///     print("\(indent)\(c.author ?? "[deleted]"): \(c.text ?? "")")
/// }
/// ```
///
/// - Note: Hacker News does not expose per-comment scores through its public
///   API, so there is no `points` field on comments.
public struct HNComment: Sendable, Identifiable {

    /// The comment's Hacker News item ID.
    public let id: Int

    /// The author's username, or `nil` if the comment was deleted.
    public let author: String?

    /// The comment body as readable plain text (HTML decoded, paragraphs kept).
    ///
    /// `nil` if the comment was deleted or removed.
    public let text: String?

    /// The original comment body as HTML, exactly as Hacker News served it.
    public let textHTML: String?

    /// When the comment was posted.
    public let createdAt: Date?

    /// The ID of the parent item (a comment, or the story for top-level comments).
    public let parentId: Int?

    /// The ID of the story this comment belongs to.
    public let storyId: Int?

    /// Nesting depth: `0` for a top-level comment, `1` for a reply, and so on.
    public let depth: Int

    /// The direct replies to this comment.
    public let children: [HNComment]

    // MARK: - Computed

    /// Whether the comment has been deleted or removed.
    public var isDeleted: Bool { author == nil || text == nil }

    /// Whether this comment has any replies.
    public var hasReplies: Bool { !children.isEmpty }

    /// The total number of descendant comments beneath this one.
    public var replyCount: Int {
        children.reduce(children.count) { $0 + $1.replyCount }
    }

    /// This comment followed by all of its descendants, depth-first.
    public var flattened: [HNComment] {
        [self] + children.flatMap(\.flattened)
    }

    /// Creates a Hacker News comment.
    public init(
        id: Int,
        author: String?,
        text: String?,
        textHTML: String?,
        createdAt: Date?,
        parentId: Int?,
        storyId: Int?,
        depth: Int,
        children: [HNComment]
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.textHTML = textHTML
        self.createdAt = createdAt
        self.parentId = parentId
        self.storyId = storyId
        self.depth = depth
        self.children = children
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
