//
//  HNHTML.swift
//  HackerNewsMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Converts Hacker News comment HTML into readable plain text.
///
/// HN serves comment bodies as a small HTML subset: `<p>` for paragraph breaks,
/// `<a href="…">…</a>` links, `<i>`, `<code>`, `<pre>`, and HTML entities such
/// as `&#x27;` and `&quot;`. This preserves paragraph breaks and link text while
/// stripping markup and decoding entities.
enum HNHTML {

    /// Renders HN comment HTML as plain text with paragraph breaks preserved.
    static func toPlainText(_ html: String) -> String {
        var text = html

        // Paragraph breaks: HN uses a bare "<p>" between paragraphs.
        text = text.replacingOccurrences(of: "</p>", with: "", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<p>", with: "\n\n", options: .caseInsensitive)

        // Links: keep the visible link text, drop the anchor markup.
        text = replaceRegex(#"<a\b[^>]*>(.*?)</a>"#, in: text, template: "$1")

        // Strip any remaining tags.
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        return unescape(text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Decodes HTML entities (named, decimal `&#123;`, and hex `&#x1F;`).
    static func unescape(_ input: String) -> String {
        var text = input

        // Named entities (leave &amp; for last so it can't double-decode).
        let named: [(String, String)] = [
            ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
            ("&#x27;", "'"), ("&#x2F;", "/"), ("&apos;", "'"), ("&nbsp;", " ")
        ]
        for (entity, replacement) in named {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }

        text = decodeNumericEntities(text)
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        return text
    }

    // MARK: - Helpers

    /// Decodes decimal (`&#123;`) and hexadecimal (`&#x7B;`) numeric entities.
    private static func decodeNumericEntities(_ input: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"&#(x?)([0-9a-fA-F]+);"#) else {
            return input
        }
        let nsInput = input as NSString
        var result = input
        let matches = regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length))
        for match in matches.reversed() {
            let isHex = nsInput.substring(with: match.range(at: 1)) == "x"
            let digits = nsInput.substring(with: match.range(at: 2))
            guard let code = UInt32(digits, radix: isHex ? 16 : 10),
                  let scalar = Unicode.Scalar(code),
                  let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: String(Character(scalar)))
        }
        return result
    }

    private static func replaceRegex(_ pattern: String, in text: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template
        )
    }
}
