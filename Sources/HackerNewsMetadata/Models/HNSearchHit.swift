//
//  HNSearchHit.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single Hacker News search result.
///
/// A hit is either a story or a comment (see ``type``). Story hits carry a
/// ``title``/``points``/``commentCount``; comment hits carry ``text`` and the
/// parent ``storyId``/``storyTitle``. Feed ``id`` (or ``storyId``) into
/// ``HackerNewsMetadata/fetchWithComments(_:)`` to pull the full thread.
///
/// ```swift
/// let results = try await HackerNewsMetadata.search("swift concurrency", in: .stories)
/// for hit in results.hits {
///     print("\(hit.title ?? "") — \(hit.points ?? 0) pts, \(hit.commentCount) comments")
/// }
/// ```
public struct HNSearchHit: Sendable, Identifiable {

    /// The item's Hacker News ID (Algolia `objectID`).
    public let id: Int

    /// The item type: `"story"`, `"comment"`, `"poll"`, `"job"`, `"pollopt"`.
    public let type: String

    /// The submitter's username.
    public let author: String?

    /// The story title (story hits only).
    public let title: String?

    /// The submitted URL (story hits only).
    public let url: String?

    /// The score in points (story hits only).
    public let points: Int?

    /// The number of comments on the story.
    public let commentCount: Int

    /// The matched text as plain text: the Ask HN body (stories) or the comment
    /// body (comments), HTML-decoded. `nil` for plain link stories.
    public let text: String?

    /// When the item was posted.
    public let createdAt: Date?

    /// For comment hits, the parent story's ID.
    public let storyId: Int?

    /// For comment hits, the parent story's title.
    public let storyTitle: String?

    /// For comment hits, the immediate parent item's ID.
    public let parentId: Int?

    /// Creates a Hacker News search hit.
    public init(
        id: Int,
        type: String,
        author: String?,
        title: String?,
        url: String?,
        points: Int?,
        commentCount: Int,
        text: String?,
        createdAt: Date?,
        storyId: Int?,
        storyTitle: String?,
        parentId: Int?
    ) {
        self.id = id
        self.type = type
        self.author = author
        self.title = title
        self.url = url
        self.points = points
        self.commentCount = commentCount
        self.text = text
        self.createdAt = createdAt
        self.storyId = storyId
        self.storyTitle = storyTitle
        self.parentId = parentId
    }
}
