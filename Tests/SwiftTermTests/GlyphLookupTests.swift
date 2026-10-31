//
//  GlyphLookupTests.swift
//
//  The parts of a glyph lookup that run once per glyph in every row build.
//
#if os(macOS)
import CoreText
import Foundation
import Testing

@testable import SwiftTerm

final class GlyphLookupTests {
    private func font(_ name: String, _ size: CGFloat = 13) -> CTFont {
        CTFontCreateWithName(name as CFString, size, nil)
    }

    private func glyph(_ font: CTFont, _ character: UniChar) -> CGGlyph {
        var character = character
        var glyph: CGGlyph = 0
        #expect(CTFontGetGlyphsForCharacters(font, &character, &glyph, 1))
        return glyph
    }

    @Test func eachFontKeepsItsOwnName() {
        let cache = FontNameCache()
        let menlo = font("Menlo-Regular"), bold = font("Menlo-Bold")
        #expect(cache.name(of: menlo) == CTFontCopyPostScriptName(menlo) as String)
        #expect(cache.name(of: bold) == CTFontCopyPostScriptName(bold) as String)
        #expect(cache.name(of: menlo) != cache.name(of: bold))
    }

    @Test func anInstanceIsOnlyAddedOnce() {
        let cache = FontNameCache()
        let menlo = font("Menlo-Regular")
        for _ in 0..<10 { _ = cache.name(of: menlo) }
        #expect(cache.count == 1)
    }

    @Test func theCacheStaysBoundedAndCorrectPastItsLimit() {
        let cache = FontNameCache(maxEntries: 4)
        let names = ["Menlo-Regular", "Menlo-Bold", "Menlo-Italic", "Menlo-BoldItalic"]
        let expected = names.map { CTFontCopyPostScriptName(font($0)) as String }
        for round in 0..<20 {
            // New instances every time, so freed addresses would be reused without the retain.
            for (index, name) in names.enumerated() {
                #expect(cache.name(of: font(name, 10 + CGFloat(round))) == expected[index])
            }
            #expect(cache.count <= 4)
        }
    }

    @Test func aSpaceIsBlankAndALetterIsNot() {
        let rasterizer = CoreTextGlyphRasterizer()
        let menlo = font("Menlo-Regular")
        #expect(rasterizer.isBlank(font: menlo, glyph: glyph(menlo, 0x20)))
        #expect(!rasterizer.isBlank(font: menlo, glyph: glyph(menlo, 0x41)))
        #expect(rasterizer.rasterize(font: menlo, glyph: glyph(menlo, 0x20)) == nil)
        #expect(rasterizer.rasterize(font: menlo, glyph: glyph(menlo, 0x41)) != nil)
    }
}
#endif
