//
//  WrapFlagRedrawTests.swift
//
//  A program that redraws in place after a resize replaces rows that reflow marked as
//  wrapped. Those rows are its own lines now: a flag left behind joins them when text is
//  read, and merges their cells at the next reflow.
//
import Foundation
import Testing

@testable import SwiftTerm

final class WrapFlagRedrawTests: TerminalDelegate {
    func send(source: Terminal, data: ArraySlice<UInt8>) {}

    private let wide = "31. Man pages: built-in docs, read with man."

    /// A long line narrowed so that reflow wraps it onto a second row, with the cursor below it.
    private func narrowedTerminal() -> Terminal {
        let terminal = Terminal(delegate: self, options: TerminalOptions(cols: 50, rows: 10, scrollback: 100))
        terminal.feed(text: wide + "\r\n> ")
        terminal.resize(cols: 30, rows: 10)
        #expect(terminal.buffer.lines[1].isWrapped)
        return terminal
    }

    private func text(_ terminal: Terminal, _ row: Int) -> String {
        terminal.buffer.lines[row].translateToString(trimRight: true)
    }

    /// Erasing keeps soft-wrap boundaries on purpose: right-to-left paragraphs rely on them.
    @Test func erasingAWholeLineKeepsItsWrapFlag() {
        let terminal = narrowedTerminal()
        terminal.feed(text: "\u{1b}[2;1H\u{1b}[2K")
        #expect(terminal.buffer.lines[1].isWrapped)
    }

    @Test func aLineFeedOntoARowClearsItsWrapFlag() {
        let terminal = narrowedTerminal()
        terminal.feed(text: "\u{1b}[1;1H\r\n")
        #expect(!terminal.buffer.lines[1].isWrapped)
    }

    @Test func movingTheCursorOntoARowKeepsItsWrapFlag() {
        let terminal = narrowedTerminal()
        terminal.feed(text: "\u{1b}[2;1H")
        #expect(terminal.buffer.lines[1].isWrapped)
    }

    @Test func aRedrawnLineIsReadAsItsOwnLine() {
        let terminal = narrowedTerminal()
        terminal.feed(text: "\u{1b}[H\u{1b}[2K31. Man pages: built-in docs,\r\n\u{1b}[2K    read with man.")
        let read = terminal.getText(start: Position(col: 0, row: 0), end: Position(col: terminal.cols, row: Int.max / 2))
        #expect(read.contains("built-in docs,\n"))
    }

    @Test func widenedRedrawnLinesStayApart() {
        let terminal = narrowedTerminal()
        terminal.feed(text: "\u{1b}[H\u{1b}[2K31. Man pages: built-in docs,\r\n\u{1b}[2K    read with man.\u{1b}[K\r\n> ")
        terminal.resize(cols: 50, rows: 10)
        #expect(text(terminal, 0) == "31. Man pages: built-in docs,")
        #expect(text(terminal, 1) == "    read with man.")
    }

    /// What is not redrawn still rewraps, in both directions.
    @Test func aLineLeftAloneStillRewraps() {
        let terminal = narrowedTerminal()
        #expect(text(terminal, 0) == "31. Man pages: built-in docs, ")
        terminal.resize(cols: 50, rows: 10)
        #expect(text(terminal, 0) == wide)
        #expect(!terminal.buffer.lines[1].isWrapped)
    }

    @Test func textRunningOverTheEdgeStillWraps() {
        let terminal = Terminal(delegate: self, options: TerminalOptions(cols: 10, rows: 5, scrollback: 100))
        terminal.feed(text: String(repeating: "x", count: 25) + "\r\n")
        #expect(terminal.buffer.lines[1].isWrapped)
        #expect(terminal.buffer.lines[2].isWrapped)
        #expect(!terminal.buffer.lines[3].isWrapped)
    }
}
