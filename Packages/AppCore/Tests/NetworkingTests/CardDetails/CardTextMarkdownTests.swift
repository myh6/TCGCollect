//
//  CardTextMarkdownTests.swift
//  AppCore
//
//  Created by Min-Yang Huang on 2026/10/30.
//

import Testing
@testable import Networking

struct CardTextMarkdownTests {

    @Test func markdown_keepsPlainText() {
        expect("[Blocker] Set up to 1 Character as active.", becomes: "[Blocker] Set up to 1 Character as active.")
    }

    @Test(arguments: [
        ("<strong>bold</strong> text", "**bold** text"),
        ("<b>bold</b> text", "**bold** text"),
        ("<em>italic</em> text", "*italic* text"),
        ("<i>italic</i> text", "*italic* text"),
        ("<strong>bold <em>and italic</em></strong>", "**bold *and italic***"),
    ])
    func markdown_turnsEmphasisIntoMarkdown(html: String, expected: String) {
        expect(html, becomes: expected)
    }

    @Test(arguments: ["<br>", "<br/>", "<br />", "<BR>", "\r\n<br>\r\n", " <br> "])
    func markdown_turnsLineBreakTagIntoNewline(lineBreak: String) {
        expect("first\(lineBreak)second", becomes: "first\nsecond")
    }

    @Test func markdown_removesLineBreaksAroundText() {
        expect("<br> text <br/>", becomes: "text")
    }

    @Test(arguments: ["\r\n", "\n", "  "])
    func markdown_treatsRawLineBreaksAndRepeatedSpacesAsOneSpace(whitespace: String) {
        expect("first\(whitespace)second", becomes: "first second")
    }

    @Test func markdown_movesSpacesOutsideEmphasis() {
        expect("<strong>You may trash </strong>1 Event", becomes: "**You may trash** 1 Event")
    }

    @Test func markdown_dropsEmptyEmphasis() {
        expect("a <strong> </strong>card", becomes: "a card")
    }

    @Test func markdown_removesOtherTags() {
        expect(#"<span class="x">a</span> <p>card</p>"#, becomes: "a card")
    }

    @Test(arguments: [
        ("&amp;", "&"),
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&quot;", "\""),
        ("&#39;", "'"),
        ("&nbsp;", " "),
    ])
    func markdown_decodesHTMLEntities(entity: String, expected: String) {
        expect("a\(entity)b", becomes: "a\(expected)b")
    }

    @Test func markdown_decodesEscapedEntityOnlyOnce() {
        expect("&amp;lt;", becomes: "&lt;")
    }

    @Test func markdown_convertsBackendDescription() {
        let html = "[Blocker] <em>(After your opponent declares an attack, you may rest this card to make it the new target of the attack.)</em>\r\n<br>\r\n[End of Your Turn] <strong>You may trash 1 Event from your hand</strong>: Set up to 1 of your [FILM] type Characters as active."

        expect(html, becomes: "[Blocker] *(After your opponent declares an attack, you may rest this card to make it the new target of the attack.)*\n[End of Your Turn] **You may trash 1 Event from your hand**: Set up to 1 of your [FILM] type Characters as active.")
    }

    // MARK: - Helpers
    private func expect(_ html: String, becomes expected: String, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(CardTextMarkdown.markdown(fromHTML: html) == expected, sourceLocation: sourceLocation)
    }
}
