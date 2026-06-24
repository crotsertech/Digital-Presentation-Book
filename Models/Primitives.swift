//
//  Primitives.swift
//  Digital Presentation Book
//
//  Small Codable value types used throughout the document model.
//

import Foundation
import SwiftUI
import CoreGraphics

/// A rectangle expressed in slide-relative coordinates (0...1). Encoded as
/// four scalars so manifests are human-readable.
struct NormalizedRect: Codable, Hashable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    static let unit = NormalizedRect(x: 0, y: 0, width: 1, height: 1)

    func cgRect(in canvas: CGSize) -> CGRect {
        CGRect(
            x: x * canvas.width,
            y: y * canvas.height,
            width: width * canvas.width,
            height: height * canvas.height
        )
    }
}

/// Codable RGBA color (sRGB, 0...1 components). Avoids platform-coupled
/// types so manifests are portable.
struct RGBAColor: Codable, Hashable, Sendable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.r = red; self.g = green; self.b = blue; self.a = alpha
    }

    init(white: Double, alpha: Double = 1.0) {
        self.r = white; self.g = white; self.b = white; self.a = alpha
    }

    var color: Color {
        Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
