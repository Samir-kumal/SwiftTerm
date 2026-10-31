#if os(macOS) || os(iOS) || os(visionOS)
import CoreText
import Foundation

/// Remembers each font instance's PostScript name. Copying the name is slow enough to dominate
/// a row build when it is done once per glyph just to form a cache key.
final class FontNameCache {
    private let maxEntries: Int
    // Holding the font keeps its address from being reused by another font.
    private var names: [ObjectIdentifier: (font: CTFont, name: String)] = [:]

    init(maxEntries: Int = 256) {
        self.maxEntries = maxEntries
    }

    var count: Int { names.count }

    func name(of font: CTFont) -> String {
        let id = ObjectIdentifier(font)
        if let cached = names[id] {
            return cached.name
        }
        if names.count >= maxEntries {
            names.removeAll()
        }
        let name = CTFontCopyPostScriptName(font) as String
        names[id] = (font, name)
        return name
    }
}
#endif
