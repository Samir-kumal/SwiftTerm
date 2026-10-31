import Foundation
import Testing
@testable import SwiftTerm

final class FullScreenRevisionTests: TerminalDelegate {
    func send(source: Terminal, data: ArraySlice<UInt8>) {}

    @Test func aFullScreenUpdateIsSeenButAWriteIsNot() {
        let terminal = Terminal(delegate: self, options: TerminalOptions(cols: 20, rows: 5))
        let start = terminal.fullScreenRevision
        terminal.feed(text: "hello")
        #expect(terminal.fullScreenRevision == start) // a line's generation covers this
        terminal.updateFullScreen()
        #expect(terminal.fullScreenRevision == start &+ 1)
    }
}
