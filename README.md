# Swift Hacker News Metadata

A Swift library for fetching Hacker News stories and their **full comment trees**. No API key or authentication required — uses Hacker News' public Algolia API, which returns an entire thread in a single request.

## Features

- 💬 **Full comment trees in one request** — story metadata plus every nested comment via `fetchWithComments(_:)`
- 🔎 **Full-text search** — `search(_:)` across stories and comments, with type/author/points/comment/date filters, relevance or date sorting, and pagination
- 🌳 **Nested + flat** — each `HNComment` carries its `children`; use `flattened` for a depth-first list with `depth` preserved
- 🧹 **Readable text** — comment HTML is decoded to plain text (paragraph breaks kept, entities decoded), with the raw `textHTML` also available
- 🔗 **Flexible input** — raw item IDs, `news.ycombinator.com/item?id=…`, or Algolia item URLs
- 🔒 **No API key required** — public `hn.algolia.com/api/v1` endpoint
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS
- ⚡ **Async/await** native
- 🛡️ **Typed error handling**

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-hackernews-metadata.git", from: "1.0.0")
]
```

## Usage

### Story + comments

```swift
import HackerNewsMetadata

let (story, comments) = try await HackerNewsMetadata.fetchWithComments(
    "https://news.ycombinator.com/item?id=8863"
)

print(story.title ?? "")
print("\(story.points ?? 0) points · \(comments.totalCount) comments")

for c in comments.flattened {
    let indent = String(repeating: "  ", count: c.depth)
    print("\(indent)\(c.author ?? "[deleted]"): \(c.text ?? "")")
}
```

### Comments only

```swift
let comments = try await HackerNewsMetadata.comments("8863")
let topLevel = comments.count
let everything = comments.totalCount
```

### Story metadata only

```swift
let story = try await HackerNewsMetadata.story("8863")
// id, type, title, url, author, text (Ask HN body), points, createdAt, commentCount
```

### Search

Full-text search over stories and comments, powered by the same keyless Algolia
API. Filter by type, author, minimum points/comments, and date range; sort by
relevance or recency; page through results.

```swift
// Relevance-ranked stories about "swift concurrency" with at least 50 points
let results = try await HackerNewsMetadata.search(
    "swift concurrency", in: .stories, sortBy: .relevance, minPoints: 50
)
print("\(results.totalHits) matches across \(results.pageCount) pages")
for hit in results.hits {
    print("\(hit.title ?? "") — \(hit.points ?? 0) pts, \(hit.commentCount) comments")
}

// Newest comments by a specific author
let byAuthor = try await HackerNewsMetadata.search(
    "", in: .comments, sortBy: .date, author: "pg"
)

// Search composes with comment fetching: find threads, then pull their trees
for hit in results.hits {
    let (_, comments) = try await HackerNewsMetadata.fetchWithComments(String(hit.id))
    // …analyse comments…
}
```

Filters: `in:` (`.all`/`.stories`/`.comments`/`.askHN`/`.showHN`/`.polls`/`.frontPage`),
`author:`, `storyId:` (comments on a story), `minPoints:`, `minComments:`,
`createdAfter:`/`createdBefore:`, and `page:`/`hitsPerPage:`.

### Error handling

```swift
do {
    let comments = try await HackerNewsMetadata.comments(input)
} catch HackerNewsMetadataError.itemNotFound {
    print("No such item")
} catch {
    print(error.localizedDescription)
}
```

## Models

| Type | Kind | Description |
|------|------|-------------|
| `HNStory` | struct | `id`, `type`, `title`, `url`, `author`, `text`, `points`, `createdAt`, `commentCount`, plus `hnURL` |
| `HNComment` | struct | `id`, `author`, `text`, `textHTML`, `createdAt`, `parentId`, `storyId`, `depth`, `children`, plus `isDeleted`, `hasReplies`, `replyCount`, `flattened` |
| `HNSearchResults` | struct | `hits`, `query`, `page`, `pageCount`, `totalHits`, `hitsPerPage`, plus `hasNextPage` |
| `HNSearchHit` | struct | `id`, `type`, `author`, `title`, `url`, `points`, `commentCount`, `text`, `createdAt`, `storyId`, `storyTitle`, `parentId`, plus `isStory`/`isComment`, `hnURL` |
| `HackerNewsMetadataError` | enum | Typed errors with `errorDescription` |

## How It Works

Hacker News' Algolia API exposes any item at `hn.algolia.com/api/v1/items/{id}`,
returning the story and its complete nested comment tree in one response. This
library extracts the item ID, requests that JSON, decodes comment HTML to plain
text, and builds a typed `HNComment` tree.

> **Note:** Hacker News does not expose per-comment scores through its public API,
> so `HNComment` has no `points` field. Deleted comments appear with `author`/`text`
> set to `nil` (`isDeleted == true`) but keep their replies.

## Testing

```bash
swift test                      # offline unit tests (fixtures)
HN_LIVE_TESTS=1 swift test      # also run the live network test
```

## License

MIT

## Author

David Sherlock
