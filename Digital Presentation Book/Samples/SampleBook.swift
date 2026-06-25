import Foundation
import SwiftUI

enum SampleBook {

    static func make() -> Book {
        let theme = BookTheme.waterworks

        let intro = Chapter(
            title: "Welcome",
            summary: "Greet the prospect and set the tone for the visit.",
            accentColor: theme.primaryColor,
            slides: [
                titleSlide(theme: theme),
                agendaSlide(theme: theme)
            ]
        )

        let problem = Chapter(
            title: "Your Water Today",
            summary: "Walk through what the test results actually mean.",
            accentColor: theme.secondaryColor,
            slides: [
                hardnessExplainerSlide(theme: theme),
                hardnessCalculatorSlide(theme: theme)
            ]
        )

        let solution = Chapter(
            title: "The Solution",
            summary: "Introduce the Hydrotech / Canature WaterGroup lineup.",
            accentColor: RGBAColor(red: 0.27, green: 0.66, blue: 0.32),
            slides: [
                solutionOverviewSlide(theme: theme),
                nextStepsSlide(theme: theme)
            ]
        )

        return Book(
            title: "Sample Water Treatment Presentation",
            subtitle: "A starter book to demo every feature.",
            author: "Starholder Softworks",
            theme: theme,
            chapters: [intro, problem, solution]
        )
    }

    private static func titleSlide(theme: BookTheme) -> Slide {
        Slide(
            title: "Title",
            notes: "Welcome the prospect, introduce yourself, set expectations for the visit.",
            background: .gradient(
                start: theme.primaryColor,
                end: theme.secondaryColor,
                angleDegrees: 135
            ),
            elements: [
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.30, width: 0.86, height: 0.20),
                    content: .text(TextElementData(
                        string: "Better Water for Your Home",
                        fontSize: 84,
                        fontWeight: .heavy,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.52, width: 0.86, height: 0.08),
                    content: .text(TextElementData(
                        string: "A free, no-obligation water analysis from your local Hydrotech / Canature WaterGroup dealer.",
                        fontSize: 28,
                        fontWeight: .medium,
                        color: RGBAColor(white: 1.0, alpha: 0.88),
                        alignment: .leading,
                        lineSpacing: 4
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.78, width: 0.30, height: 0.10),
                    content: .shape(ShapeElementData(
                        kind: .roundedRectangle,
                        fill: RGBAColor(white: 1.0, alpha: 0.18),
                        stroke: RGBAColor(white: 1.0, alpha: 0.55),
                        strokeWidth: 1.5,
                        cornerRadius: 14
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.78, width: 0.30, height: 0.10),
                    content: .text(TextElementData(
                        string: "Water · Air · You",
                        fontSize: 24,
                        fontWeight: .semibold,
                        color: RGBAColor(white: 1.0),
                        alignment: .center,
                        lineSpacing: 0
                    ))
                )
            ]
        )
    }

    private static func agendaSlide(theme: BookTheme) -> Slide {
        Slide(
            title: "Agenda",
            background: .solid(theme.backgroundColor),
            elements: [
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.10, width: 0.86, height: 0.12),
                    content: .text(TextElementData(
                        string: "Here's What We'll Cover Today",
                        fontSize: 56,
                        fontWeight: .bold,
                        color: theme.primaryColor,
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.28, width: 0.86, height: 0.55),
                    content: .text(TextElementData(
                        string:
                            "1. A quick look at your home's water test results\n" +
                            "2. What hard water actually costs you each year\n" +
                            "3. The Hydrotech / Canature WaterGroup solution that fits your home\n" +
                            "4. Your questions, and next steps",
                        fontSize: 32,
                        fontWeight: .medium,
                        color: theme.defaultTextColor,
                        alignment: .leading,
                        lineSpacing: 14
                    ))
                )
            ]
        )
    }

    private static func hardnessExplainerSlide(theme: BookTheme) -> Slide {
        Slide(
            title: "What is Hard Water?",
            background: .solid(theme.backgroundColor),
            elements: [
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.08, width: 0.86, height: 0.10),
                    content: .text(TextElementData(
                        string: "What Is Hard Water?",
                        fontSize: 56,
                        fontWeight: .bold,
                        color: theme.primaryColor,
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.22, width: 0.86, height: 0.18),
                    content: .text(TextElementData(
                        string:
                            "\"Hard\" water carries dissolved minerals (mostly calcium and magnesium) " +
                            "picked up as rain water moves through the ground. Those minerals are " +
                            "harmless to drink, but they wreak havoc on your plumbing, your appliances, " +
                            "and your skin.",
                        fontSize: 26,
                        fontWeight: .regular,
                        color: theme.defaultTextColor,
                        alignment: .leading,
                        lineSpacing: 8
                    ))
                ),

                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.48, width: 0.27, height: 0.40),
                    content: .shape(ShapeElementData(
                        kind: .roundedRectangle,
                        fill: theme.secondaryColor,
                        stroke: nil,
                        strokeWidth: 0,
                        cornerRadius: 16
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.10, y: 0.52, width: 0.21, height: 0.32),
                    content: .text(TextElementData(
                        string: "Scale\nbuildup\non heating\nelements",
                        fontSize: 24,
                        fontWeight: .semibold,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 4
                    ))
                ),

                SlideElement(
                    frame: NormalizedRect(x: 0.365, y: 0.48, width: 0.27, height: 0.40),
                    content: .shape(ShapeElementData(
                        kind: .roundedRectangle,
                        fill: theme.primaryColor,
                        stroke: nil,
                        strokeWidth: 0,
                        cornerRadius: 16
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.395, y: 0.52, width: 0.21, height: 0.32),
                    content: .text(TextElementData(
                        string: "More\nsoap and\ndetergent\nrequired",
                        fontSize: 24,
                        fontWeight: .semibold,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 4
                    ))
                ),

                SlideElement(
                    frame: NormalizedRect(x: 0.66, y: 0.48, width: 0.27, height: 0.40),
                    content: .shape(ShapeElementData(
                        kind: .roundedRectangle,
                        fill: RGBAColor(red: 0.27, green: 0.66, blue: 0.32),
                        stroke: nil,
                        strokeWidth: 0,
                        cornerRadius: 16
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.69, y: 0.52, width: 0.21, height: 0.32),
                    content: .text(TextElementData(
                        string: "Shorter\nappliance\nlifespan",
                        fontSize: 24,
                        fontWeight: .semibold,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 4
                    ))
                )
            ]
        )
    }

    private static func hardnessCalculatorSlide(theme: BookTheme) -> Slide {
        Slide(
            title: "What's It Costing You?",
            notes: "Hand the iPad to the prospect. Let them drive the sliders.",
            background: .solid(theme.backgroundColor),
            elements: [
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.06, width: 0.86, height: 0.10),
                    content: .text(TextElementData(
                        string: "What's Hard Water Costing You?",
                        fontSize: 52,
                        fontWeight: .bold,
                        color: theme.primaryColor,
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.20, width: 0.86, height: 0.74),
                    content: .widget(WidgetElementData(
                        widgetID: HardnessCalculatorWidget.widgetID,
                        parameters: HardnessCalculatorWidget.defaultParameters
                    ))
                )
            ]
        )
    }

    private static func solutionOverviewSlide(theme: BookTheme) -> Slide {
        Slide(
            title: "The Hydrotech / Canature WaterGroup Solution",
            background: .gradient(
                start: theme.backgroundColor,
                end: RGBAColor(red: 0.93, green: 0.96, blue: 0.99),
                angleDegrees: 180
            ),
            elements: [
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.10, width: 0.86, height: 0.12),
                    content: .text(TextElementData(
                        string: "Built for Real Homes",
                        fontSize: 56,
                        fontWeight: .bold,
                        color: theme.primaryColor,
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.28, width: 0.86, height: 0.60),
                    content: .text(TextElementData(
                        string:
                            "• Twin-tank design means you always have soft water, never an off cycle.\n\n" +
                            "• Non-electric, demand-driven operation only uses salt when you actually use water.\n\n" +
                            "• 10-year warranty on the control valve. Built in the USA.\n\n" +
                            "• Whisper-quiet regeneration that won't wake the household.",
                        fontSize: 30,
                        fontWeight: .medium,
                        color: theme.defaultTextColor,
                        alignment: .leading,
                        lineSpacing: 6
                    ))
                )
            ]
        )
    }

    private static func nextStepsSlide(theme: BookTheme) -> Slide {
        Slide(
            title: "Next Steps",
            background: .solid(theme.primaryColor),
            elements: [
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.22, width: 0.86, height: 0.18),
                    content: .text(TextElementData(
                        string: "Ready to Make the Switch?",
                        fontSize: 72,
                        fontWeight: .heavy,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.46, width: 0.86, height: 0.30),
                    content: .text(TextElementData(
                        string:
                            "We'll get installation on the calendar this week, walk you through " +
                            "financing options, and have soft water in your home before the weekend.",
                        fontSize: 28,
                        fontWeight: .medium,
                        color: RGBAColor(white: 1.0, alpha: 0.92),
                        alignment: .leading,
                        lineSpacing: 6
                    ))
                )
            ]
        )
    }
}
