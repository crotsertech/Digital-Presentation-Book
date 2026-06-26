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
            summary: "Introduce a softener or filter that fits the home.",
            accentColor: RGBAColor(red: 0.27, green: 0.66, blue: 0.32),
            slides: [
                solutionOverviewSlide(theme: theme),
                nextStepsSlide(theme: theme)
            ]
        )

        return Book(
            title: "Sample Water Treatment Presentation",
            subtitle: "A starter book to demo every feature.",
            author: "Your Dealership",
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
                    frame: NormalizedRect(x: 0.07, y: 0.34, width: 0.86, height: 0.18),
                    content: .text(TextElementData(
                        string: "Better Water for Your Home",
                        fontSize: 64,
                        fontWeight: .heavy,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.56, width: 0.86, height: 0.10),
                    content: .text(TextElementData(
                        string: "A free, no-obligation water analysis from your local water treatment dealer.",
                        fontSize: 24,
                        fontWeight: .medium,
                        color: RGBAColor(white: 1.0, alpha: 0.88),
                        alignment: .leading,
                        lineSpacing: 4
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
                        fontSize: 44,
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
                            "3. The right softener or filter for your home\n" +
                            "4. Your questions, and next steps",
                        fontSize: 28,
                        fontWeight: .medium,
                        color: theme.defaultTextColor,
                        alignment: .leading,
                        lineSpacing: 12
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
                        fontSize: 44,
                        fontWeight: .bold,
                        color: theme.primaryColor,
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.20, width: 0.86, height: 0.22),
                    content: .text(TextElementData(
                        string:
                            "\"Hard\" water carries dissolved minerals (mostly calcium and magnesium) " +
                            "picked up as rain water moves through the ground. Those minerals are " +
                            "harmless to drink, but they wreak havoc on your plumbing, your appliances, " +
                            "and your skin.",
                        fontSize: 22,
                        fontWeight: .regular,
                        color: theme.defaultTextColor,
                        alignment: .leading,
                        lineSpacing: 6
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
                    frame: NormalizedRect(x: 0.10, y: 0.54, width: 0.21, height: 0.30),
                    content: .text(TextElementData(
                        string: "Scale buildup on heating elements",
                        fontSize: 20,
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
                    frame: NormalizedRect(x: 0.395, y: 0.54, width: 0.21, height: 0.30),
                    content: .text(TextElementData(
                        string: "More soap and detergent required",
                        fontSize: 20,
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
                    frame: NormalizedRect(x: 0.69, y: 0.54, width: 0.21, height: 0.30),
                    content: .text(TextElementData(
                        string: "Shorter appliance lifespan",
                        fontSize: 20,
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
                        fontSize: 40,
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
            title: "The Right System for Your Home",
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
                        fontSize: 48,
                        fontWeight: .bold,
                        color: theme.primaryColor,
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.26, width: 0.86, height: 0.66),
                    content: .text(TextElementData(
                        string:
                            "• Sized to your home's actual usage, not a generic spec sheet.\n\n" +
                            "• Efficient regeneration only when you've used enough water to need it.\n\n" +
                            "• Backed by a manufacturer warranty and your dealer's local service.\n\n" +
                            "• Quiet enough to install near living spaces.",
                        fontSize: 24,
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
                    frame: NormalizedRect(x: 0.07, y: 0.26, width: 0.86, height: 0.18),
                    content: .text(TextElementData(
                        string: "Ready to Make the Switch?",
                        fontSize: 56,
                        fontWeight: .heavy,
                        color: RGBAColor(white: 1.0),
                        alignment: .leading,
                        lineSpacing: 0
                    ))
                ),
                SlideElement(
                    frame: NormalizedRect(x: 0.07, y: 0.48, width: 0.86, height: 0.30),
                    content: .text(TextElementData(
                        string:
                            "We'll get installation on the calendar this week, walk you through " +
                            "your options, and have better water in your home soon.",
                        fontSize: 22,
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
