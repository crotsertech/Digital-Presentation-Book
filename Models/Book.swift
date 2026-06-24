//
//  Book.swift
//  Digital Presentation Book
//
//  Top-level document model. A Book bundles ordered chapters of slides and
//  carries presentation-wide settings such as theme and aspect ratio.
//

import Foundation
import SwiftUI

/// Document-format version. Bump on breaking changes to `manifest.json`.
let kDPBFormatVersion: Int = 1

/// The aspect ratio a presentation should render at. Slides always render
/// inside a letterboxed canvas of this ratio so layout is stable across
/// devices.
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

    var displayName: String {
        switch self {
        case .widescreen16x9: return "Widescreen (16:9)"
        case .standard4x3:    return "Standard (4:3)"
        case .tall9x16:       return "Portrait (9:16)"
        }
    }
}

/// Visual theme defaults that slide elements can inherit from.
struct BookTheme: Codable, Hashable, Sendable {
    var backgroundColor: RGBAColor
    var primaryColor: RGBAColor
    var secondaryColor: RGBAColor
    var defaultTextColor: RGBAColor
    var defaultFontFamily: String

    static let kineticoInspired = BookTheme(
        backgroundColor: RGBAColor(white: 1.0),
        primaryColor: RGBAColor(red: 0.0, green: 0.36, blue: 0.62),
        secondaryColor: RGBAColor(red: 0.10, green: 0.62, blue: 0.85),
        defaultTextColor: RGBAColor(white: 0.13),
        defaultFontFamily: "SF Pro"
    )
}

/// The root presentation document.
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

    /// Bumped each time the document is mutated by the editor. Stored next to
    /// the manifest so importers can detect newer copies.
    var revision: Int

    /// Schema version of the on-disk manifest. Defaults to the current
    /// constant when the book is created.
    var formatVersion: Int

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String = "",
        author: String = "",
        aspectRatio: BookAspectRatio = .widescreen16x9,
        theme: BookTheme = .kineticoInspired,
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

    /// Flat ordered slide list across all chapters. Useful for the player's
    /// linear navigation model.
    var allSlides: [Slide] {
        chapters.flatMap { $0.slides }
    }

    /// Returns the chapter index and intra-chapter slide index for a global
    /// slide index, or nil if out of range.
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
