import Foundation

struct Chapter: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var summary: String
    var accentColor: RGBAColor?
    var slides: [Slide]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String = "",
        accentColor: RGBAColor? = nil,
        slides: [Slide] = []
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.accentColor = accentColor
        self.slides = slides
    }
}
