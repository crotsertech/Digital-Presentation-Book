import Foundation
import SwiftUI

/// Document-format version. Bump on breaking changes to `manifest.json`.
let kDPBFormatVersion: Int = 1

/// Each ratio carries a `nominalSize`, the design-time point grid the slide
/// is laid out in. Renderers scale absolute-point values (font, stroke,
/// corner radius) by `actualHeight / nominalHeight`, so a book authored on a
/// Mac at 1920pt wide looks the same when projected on an iPad at 1024pt.
enum BookAspectRatio: String, Codable, CaseIterable, Identifiable, Sendable {
    case widescreen16x9
    case standard4x3
    case tall9x16

    var id: String { rawValue }

    var ratio: CGFloat {
        switch self {
        case .widescreen16x9: return 16.0 / 9.0
        case .standard4x3:    return 4.0 / 3.0
        case .tall9x16:       return 9.0 / 16.0
        }
    }

    /// 1024×768 mirrors the iPad's native point grid, the target hardware
    /// for these presentations.
    var nominalSize: CGSize {
        switch self {
        case .standard4x3:    return CGSize(width: 1024, height: 768)
        case .widescreen16x9: return CGSize(width: 1920, height: 1080)
        case .tall9x16:       return CGSize(width: 1080, height: 1920)
        }
    }

    var displayName: String {
        switch self {
        case .widescreen16x9: return "Widescreen (16:9)"
        case .standard4x3:    return "Standard (4:3)"
        case .tall9x16:       return "Portrait (9:16)"
        }
    }
}

struct BookTheme: Codable, Hashable, Sendable {
    var backgroundColor: RGBAColor
    var primaryColor: RGBAColor
    var secondaryColor: RGBAColor
    var defaultTextColor: RGBAColor
    var defaultFontFamily: String

    static let waterworks = BookTheme(
        backgroundColor: RGBAColor(white: 1.0),
        primaryColor: RGBAColor(red: 0.0, green: 0.36, blue: 0.62),
        secondaryColor: RGBAColor(red: 0.10, green: 0.62, blue: 0.85),
        defaultTextColor: RGBAColor(white: 0.13),
        defaultFontFamily: "SF Pro"
    )
}

struct Book: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var subtitle: String
    var author: String
    var aspectRatio: BookAspectRatio
    var theme: BookTheme
    var chapters: [Chapter]
    var createdAt: Date
    var updatedAt: Date

    /// Bumped each time the editor mutates the document. Stored next to the
    /// manifest so importers can detect newer copies.
    var revision: Int

    var formatVersion: Int

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        author: String = "",
        aspectRatio: BookAspectRatio = .standard4x3,
        theme: BookTheme = .waterworks,
        chapters: [Chapter] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        revision: Int = 1,
        formatVersion: Int = kDPBFormatVersion
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.author = author
        self.aspectRatio = aspectRatio
        self.theme = theme
        self.chapters = chapters
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.revision = revision
        self.formatVersion = formatVersion
    }

    /// All slides in order, including hidden ones. Used by the editor.
    var allSlides: [Slide] {
        chapters.flatMap { $0.slides }
    }

    /// Slides the player should show. Hidden ones filtered out.
    var presentableSlides: [Slide] {
        chapters.flatMap { $0.slides }.filter { !$0.isHidden }
    }

    func location(forGlobalIndex globalIndex: Int) -> (chapter: Int, slide: Int)? {
        var remaining = globalIndex
        for (cIdx, chapter) in chapters.enumerated() {
            if remaining < chapter.slides.count {
                return (cIdx, remaining)
            }
            remaining -= chapter.slides.count
        }
        return nil
    }
}
