//
//  BackgroundPresets.swift
//  Digital Presentation Book
//
//  Curated slide backgrounds picked to feel right for a water-treatment
//  sales presentation: lots of cool blues, soft mist gradients, and a
//  couple of darker hero variants for title slides.
//

import Foundation
import SwiftUI

enum BackgroundPreset: String, CaseIterable, Identifiable, Sendable {
    case themeDefault
    case pureWhite
    case softSky
    case coolMist
    case springWater
    case glacier
    case deepBlue
    case oceanDepth
    case midnight
    case slate
    case brandGradient

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .themeDefault:   return "Theme Default"
        case .pureWhite:      return "Pure White"
        case .softSky:        return "Soft Sky"
        case .coolMist:       return "Cool Mist"
        case .springWater:    return "Spring Water"
        case .glacier:        return "Glacier"
        case .deepBlue:       return "Deep Blue"
        case .oceanDepth:     return "Ocean Depth"
        case .midnight:       return "Midnight"
        case .slate:          return "Slate"
        case .brandGradient:  return "Brand Gradient"
        }
    }

    var summary: String {
        switch self {
        case .themeDefault:  return "Use the book's theme background."
        case .pureWhite:     return "Clean white for content-dense slides."
        case .softSky:       return "White fading to a hint of pale blue."
        case .coolMist:      return "Cool grey-blue, easy on the eyes."
        case .springWater:   return "Refreshing cyan with a soft gradient."
        case .glacier:       return "Crisp aqua gradient, bright and clear."
        case .deepBlue:      return "Confident mid-blue for body slides."
        case .oceanDepth:    return "Saturated navy → cyan, great for hero slides."
        case .midnight:      return "Dark navy for high-contrast titles."
        case .slate:         return "Neutral grey gradient, brand-agnostic."
        case .brandGradient: return "Uses the book's primary and secondary colors."
        }
    }

    /// Whether this preset shows white-on-dark text well by default.
    var prefersLightForeground: Bool {
        switch self {
        case .deepBlue, .oceanDepth, .midnight, .brandGradient: return true
        default: return false
        }
    }

    // MARK: - Background producer

    /// Concrete `SlideBackground` ready to assign to a slide.
    func makeBackground(book: Book) -> SlideBackground {
        switch self {
        case .themeDefault:
            return .themeDefault

        case .pureWhite:
            return .solid(RGBAColor(white: 1.0))

        case .softSky:
            return .gradient(
                start: RGBAColor(red: 1.0,  green: 1.0,  blue: 1.0),
                end:   RGBAColor(red: 0.85, green: 0.93, blue: 0.99),
                angleDegrees: 180
            )

        case .coolMist:
            return .solid(RGBAColor(red: 0.92, green: 0.95, blue: 0.98))

        case .springWater:
            return .gradient(
                start: RGBAColor(red: 0.78, green: 0.92, blue: 0.97),
                end:   RGBAColor(red: 0.36, green: 0.74, blue: 0.92),
                angleDegrees: 160
            )

        case .glacier:
            return .gradient(
                start: RGBAColor(red: 0.90, green: 0.98, blue: 1.00),
                end:   RGBAColor(red: 0.55, green: 0.86, blue: 0.94),
                angleDegrees: 200
            )

        case .deepBlue:
            return .gradient(
                start: RGBAColor(red: 0.13, green: 0.40, blue: 0.66),
                end:   RGBAColor(red: 0.07, green: 0.27, blue: 0.50),
                angleDegrees: 200
            )

        case .oceanDepth:
            return .gradient(
                start: RGBAColor(red: 0.04, green: 0.15, blue: 0.36),
                end:   RGBAColor(red: 0.08, green: 0.55, blue: 0.80),
                angleDegrees: 135
            )

        case .midnight:
            return .gradient(
                start: RGBAColor(red: 0.03, green: 0.06, blue: 0.18),
                end:   RGBAColor(red: 0.07, green: 0.16, blue: 0.34),
                angleDegrees: 200
            )

        case .slate:
            return .gradient(
                start: RGBAColor(red: 0.94, green: 0.95, blue: 0.97),
                end:   RGBAColor(red: 0.78, green: 0.80, blue: 0.84),
                angleDegrees: 180
            )

        case .brandGradient:
            return .gradient(
                start: book.theme.primaryColor,
                end:   book.theme.secondaryColor,
                angleDegrees: 135
            )
        }
    }
}
