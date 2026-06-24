//
//  Slide.swift
//  Digital Presentation Book
//

import Foundation

/// A single page in the presentation. Slides hold ordered elements rendered
/// in z-order (later = on top) plus an optional background fill or asset.
struct Slide: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var notes: String
    var background: SlideBackground
    var elements: [SlideElement]

    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String = "",
        background: SlideBackground = .themeDefault,
        elements: [SlideElement] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.background = background
        self.elements = elements
    }
}

/// Optional background treatment applied behind every element.
enum SlideBackground: Codable, Hashable, Sendable {
    case themeDefault
    case solid(RGBAColor)
    case gradient(start: RGBAColor, end: RGBAColor, angleDegrees: Double)
    case image(AssetReference, fill: ImageFill)
}

/// How a background image fits the slide canvas.
enum ImageFill: String, Codable, Hashable, Sendable {
    case aspectFit
    case aspectFill
    case stretch
}
