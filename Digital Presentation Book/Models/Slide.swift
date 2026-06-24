import Foundation

struct Slide: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var notes: String
    var background: SlideBackground
    var elements: [SlideElement]
    /// When true, this slide is offered in the "Add Slide" menu as a
    /// duplicable template so the rep can reuse layouts across the book.
    var isTemplate: Bool
    /// When true, the player skips this slide entirely. It stays visible in
    /// the editor so the rep can toggle it back on.
    var isHidden: Bool

    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String = "",
        background: SlideBackground = .themeDefault,
        elements: [SlideElement] = [],
        isTemplate: Bool = false,
        isHidden: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.background = background
        self.elements = elements
        self.isTemplate = isTemplate
        self.isHidden = isHidden
    }

    // Manual decode so books saved before isTemplate/isHidden existed still load.
    private enum CodingKeys: String, CodingKey {
        case id, title, notes, background, elements, isTemplate, isHidden
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.notes = try c.decode(String.self, forKey: .notes)
        self.background = try c.decode(SlideBackground.self, forKey: .background)
        self.elements = try c.decode([SlideElement].self, forKey: .elements)
        self.isTemplate = try c.decodeIfPresent(Bool.self, forKey: .isTemplate) ?? false
        self.isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
    }
}

enum SlideBackground: Codable, Hashable, Sendable {
    case themeDefault
    case solid(RGBAColor)
    case gradient(start: RGBAColor, end: RGBAColor, angleDegrees: Double)
    case image(AssetReference, fill: ImageFill)
}

enum ImageFill: String, Codable, Hashable, Sendable {
    case aspectFit
    case aspectFill
    case stretch
}
