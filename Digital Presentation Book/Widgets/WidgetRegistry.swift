import SwiftUI

/// Central catalogue. Adding a new widget is a one-line change in `all`
/// plus the widget's own file.
@MainActor
enum WidgetRegistry {

    static let all: [SlideWidget.Type] = [
        HardnessCalculatorWidget.self
    ]

    static func widget(forID id: String) -> SlideWidget.Type? {
        all.first { $0.widgetID == id }
    }

    /// Renders the widget for `data`, or a placeholder if the ID is unknown
    /// (e.g. opening a book whose widget type was removed in a later build).
    @ViewBuilder
    static func render(_ data: WidgetElementData) -> some View {
        if let widget = widget(forID: data.widgetID) {
            widget.makeView(parameters: data.parameters)
        } else {
            UnknownWidgetPlaceholder(widgetID: data.widgetID)
        }
    }
}

private struct UnknownWidgetPlaceholder: View {
    let widgetID: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.square.dashed")
                .font(.largeTitle)
            Text("Unknown widget")
                .font(.headline)
            Text(widgetID)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
}
