//
//  HNStory.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Hacker News item's top-level metadata (story, Ask HN, job, or poll).
///
/// Fetched from Hacker News' public Algolia API without authentication.
///
/// ```swift
/// let story = try await HackerNewsMetadata.story("48854168")
/// print(story.title ?? "")
/// print("\(story.points ?? 0) points · \(story.commentCount) comments")
/// ```
public struct HNStory: Sendable, Identifiable {

    /// The Hacker News item ID.
    public let id: Int

    /// The item type: `"story"`, `"comment"`, `"job"`, `"poll"`, `"pollopt"`.
    public let type: String

    /// The title, for stories and jobs.
    public let title: String?

    /// The submitted URL, for link stories.
    public let url: String?

    /// The submitter's username, or `nil` if deleted.
    public let author: String?

    /// The self/body text (Ask HN, text posts), decoded to plain text.
    public let text: String?

    /// The score (points). `nil` when not applicable.
    public let points: Int?

    /// When the item was posted.
    public let createdAt: Date?

    /// The total number of comments in the thread (all descendants).
    public let commentCount: Int

    /// Creates a Hacker News story.
    public init(
        id: Int,
        type: String,
        title: String?,
        url: String?,
        author: String?,
        text: String?,
        points: Int?,
        createdAt: Date?,
        commentCount: Int
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.url = url
        self.author = author
        self.text = text
        self.points = points
        self.createdAt = createdAt
        self.commentCount = commentCount
    }
}
