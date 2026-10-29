//
//  CardTextMarkdown.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Foundation

enum CardTextMarkdown {
    private static let entitiesWithAmpersandLast = [
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&quot;", "\""),
        ("&#39;", "'"),
        ("&nbsp;", " "),
        ("&amp;", "&"),
    ]

    static func markdown(fromHTML html: String) -> String {
        var text = html.replacing(/\r\n|\r|\n/, with: " ")
        text = text.replacing(/<br\s*\/?>/.ignoresCase(), with: "\n")
        text = emphasizing(text, tags: ["em", "i"], with: "*")
        text = emphasizing(text, tags: ["strong", "b"], with: "**")
        text = text.replacing(/<[^>]+>/, with: "")
        text = decodingEntities(in: text)
        return tidyingSpaces(in: text)
    }

    private static func emphasizing(_ text: String, tags: [String], with marker: String) -> String {
        tags.reduce(text) { text, tag in
            let element = try! Regex("<\(tag)(\\s[^>]*)?>(.*?)</\(tag)\\s*>").ignoresCase().dotMatchesNewlines()
            return text.replacing(element) { match in
                emphasized(match.output[2].substring.map(String.init) ?? "", with: marker)
            }
        }
    }

    private static func emphasized(_ content: String, with marker: String) -> String {
        let core = content.trimmingCharacters(in: .whitespaces)
        guard !core.isEmpty else { return content }
        let leading = content.prefix { $0 == " " }
        let trailing = String(content.reversed().prefix { $0 == " " })
        return "\(leading)\(marker)\(core)\(marker)\(trailing)"
    }

    private static func decodingEntities(in text: String) -> String {
        entitiesWithAmpersandLast.reduce(text) { text, entity in
            text.replacingOccurrences(of: entity.0, with: entity.1)
        }
    }

    private static func tidyingSpaces(in text: String) -> String {
        text.replacing(/[ ]+/, with: " ")
            .replacing(/[ ]*\n[ ]*/, with: "\n")
            .trimmingCharacters(in: .whitespaces)
    }
}
