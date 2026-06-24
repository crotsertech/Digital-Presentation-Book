import Foundation
import CoreGraphics

struct SlideElement: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var frame: NormalizedRect
    var rotationDegrees: Double
    var opacity: Double
    var locked: Bool
    var content: SlideElementContent

    init(
        id: UUID = UUID(),
        frame: NormalizedRect,
        rotationDegrees: Double = 0,
        opacity: Double = 1,
        locked: Bool = false,
        content: SlideElementContent
    ) {
        self.id = id
        self.frame = frame
        self.rotationDegrees = rotationDegrees
        self.opacity = opacity
        self.locked = locked
        self.content = content
    }
}

/// Kind-specific payload kept separate from frame/rotation/opacity so the
/// outer envelope stays uniform across element types.
enum SlideElementContent: Codable, Hashable, Sendable {
    case text(TextElementData)
    case image(ImageElementData)
    case video(VideoElementData)
    case shape(ShapeElementData)
    case widget(WidgetElementData)
}

struct TextElementData: Codable, Hashable, Sendable {
    var string: String
    var fontSize: Double
    var fontWeight: TextWeight
    var color: RGBAColor
    var alignment: TextAlignment
    var lineSpacing: Double
    /// PostScript name of a custom font. `nil` means use the system font;
    /// older documents that omit this field decode as `nil` automatically.
    var fontFamily: String?

    enum TextWeight: String, Codable, Sendable {
        case regular, medium, semibold, bold, heavy
    }

    enum TextAlignment: String, Codable, Sendable {
        case leading, center, trailing
    }
}

struct ImageElementData: Codable, Hashable, Sendable {
    var asset: AssetReference
    var fill: ImageFill
    var cornerRadius: Double
}

struct VideoElementData: Codable, Hashable, Sendable {
    var asset: AssetReference
    var autoplay: Bool
    var loops: Bool
    var showsControls: Bool
    var muted: Bool
}

struct ShapeElementData: Codable, Hashable, Sendable {
    var kind: ShapeKind
    var fill: RGBAColor
    var stroke: RGBAColor?
    var strokeWidth: Double
    var cornerRadius: Double

    enum ShapeKind: String, Codable, Sendable {
        case rectangle, ellipse, roundedRectangle
    }
}

/// Interactive component identified by `widgetID` and parameterized by a
/// dictionary the widget knows how to interpret.
struct WidgetElementData: Codable, Hashable, Sendable {
    var widgetID: String
    var parameters: [String: WidgetParameterValue]
}

/// JSON-safe widget parameter. Lets simple config round-trip through
/// `manifest.json` without losing types.
enum WidgetParameterValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case stringList([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) {
            self = .bool(v); return
        }
        if let v = try? container.decode(Double.self) {
            self = .number(v); return
        }
        if let v = try? container.decode([String].self) {
            self = .stringList(v); return
        }
        if let v = try? container.decode(String.self) {
            self = .string(v); return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported WidgetParameterValue"
        )
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v):     try c.encode(v)
        case .number(let v):     try c.encode(v)
        case .bool(let v):       try c.encode(v)
        case .stringList(let v): try c.encode(v)
        }
    }
}
