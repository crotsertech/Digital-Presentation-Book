import Foundation
import SwiftUI

enum BookTemplate: String, CaseIterable, Identifiable, Sendable {
    case blank
    case salesCall
    case followUp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blank:     return "Blank Book"
        case .salesCall: return "In-Home Sales Call"
        case .followUp:  return "Follow-Up Visit"
        }
    }

    var summary: String {
        switch self {
        case .blank:
            return "Start with a single empty slide and build everything from scratch."
        case .salesCall:
            return "3-chapter structure: Welcome, Your Water Today, The Solution. Includes the hardness cost calculator."
        case .followUp:
            return "Short deck for return visits: recap, equipment install, next steps."
        }
    }

    var iconSystemName: String {
        switch self {
        case .blank:     return "rectangle.dashed"
        case .salesCall: return "drop.fill"
        case .followUp:  return "checkmark.seal.fill"
        }
    }

    var accent: Color {
        switch self {
        case .blank:     return .gray
        case .salesCall: return .blue
        case .followUp:  return .green
        }
    }

    /// Each call generates new UUIDs so two books made from the same
    /// template don't collide.
    @MainActor
    func makeBook(title: String? = nil) -> Book {
        switch self {
        case .blank:
            return Self.makeBlank(title: title ?? "Untitled Book")
        case .salesCall:
            return Self.makeSalesCall(title: title)
        case .followUp:
            return Self.makeFollowUp(title: title ?? "Follow-Up Visit")
        }
    }

    @MainActor
    private static func makeBlank(title: String) -> Book {
        Book(
            title: title,
            subtitle: "",
            author: "",
            chapters: [
                Chapter(
                    title: "Chapter 1",
                    slides: [
                        Slide(
                            title: "Slide 1",
                            elements: [
                                SlideElement(
                                    frame: NormalizedRect(x: 0.1, y: 0.4, width: 0.8, height: 0.2),
                                    content: .text(TextElementData(
                                        string: "Your title here",
                                        fontSize: 64,
                                        fontWeight: .bold,
                                        color: BookTheme.waterworks.defaultTextColor,
                                        alignment: .center,
                                        lineSpacing: 0
                                    ))
                                )
                            ]
                        )
                    ]
                )
            ]
        )
    }

    @MainActor
    private static func makeSalesCall(title: String?) -> Book {
        var book = SampleBook.make()
        book.id = UUID()
        book.title = title ?? "New In-Home Presentation"
        book.subtitle = "Tailored for this customer."
        book.createdAt = .now
        book.updatedAt = .now
        book.revision = 1
        // Re-stamp chapter, slide, and element UUIDs so editing this copy
        // doesn't collide with any other book made from the same template.
        book.chapters = book.chapters.map { chapter in
            var c = chapter
            c.id = UUID()
            c.slides = c.slides.map { slide in
                var s = slide
                s.id = UUID()
                s.elements = s.elements.map { el in
                    var copy = el
                    copy.id = UUID()
                    return copy
                }
                return s
            }
            return c
        }
        return book
    }

    @MainActor
    private static func makeFollowUp(title: String) -> Book {
        let theme = BookTheme.waterworks
        return Book(
            title: title,
            subtitle: "Welcoming the customer to clean water.",
            author: "",
            theme: theme,
            chapters: [
                Chapter(
                    title: "Recap",
                    accentColor: theme.primaryColor,
                    slides: [
                        Slide(
                            title: "Thanks for choosing us",
                            background: .gradient(
                                start: theme.primaryColor,
                                end: theme.secondaryColor,
                                angleDegrees: 135
                            ),
                            elements: [
                                SlideElement(
                                    frame: NormalizedRect(x: 0.08, y: 0.36, width: 0.84, height: 0.18),
                                    content: .text(TextElementData(
                                        string: "Welcome to better water.",
                                        fontSize: 72,
                                        fontWeight: .heavy,
                                        color: RGBAColor(white: 1.0),
                                        alignment: .leading,
                                        lineSpacing: 0
                                    ))
                                )
                            ]
                        )
                    ]
                ),
                Chapter(
                    title: "Equipment Tour",
                    accentColor: theme.secondaryColor,
                    slides: [
                        Slide(
                            title: "How to use your new system",
                            elements: [
                                SlideElement(
                                    frame: NormalizedRect(x: 0.08, y: 0.1, width: 0.84, height: 0.12),
                                    content: .text(TextElementData(
                                        string: "Walk-Through",
                                        fontSize: 56,
                                        fontWeight: .bold,
                                        color: theme.primaryColor,
                                        alignment: .leading,
                                        lineSpacing: 0
                                    ))
                                )
                            ]
                        )
                    ]
                ),
                Chapter(
                    title: "Next Steps",
                    accentColor: RGBAColor(red: 0.27, green: 0.66, blue: 0.32),
                    slides: [
                        Slide(
                            title: "What's next",
                            elements: [
                                SlideElement(
                                    frame: NormalizedRect(x: 0.08, y: 0.36, width: 0.84, height: 0.30),
                                    content: .text(TextElementData(
                                        string: "Service reminders, referral program, and your annual check-up.",
                                        fontSize: 32,
                                        fontWeight: .medium,
                                        color: theme.defaultTextColor,
                                        alignment: .leading,
                                        lineSpacing: 6
                                    ))
                                )
                            ]
                        )
                    ]
                )
            ]
        )
    }
}
