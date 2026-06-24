//
//  WidgetRegistry.swift
//  Digital Presentation Book
//
//  Central catalogue of available widgets. Adding a new widget is a
//  one-line change here plus the widget's own file.
//

import SwiftUI

@MainActor
enum WidgetRegistry {

    /// All widgets known to the app, in display order.
    static let all: [SlideWidget.Type] = [
        HardnessCalculatorWidget.self
    ]

    static func widget(forID id: String) -> SlideWidget.Type? {
        all.first { $0.widgetID == id }
    }

    /// Render a widget instance from its persisted data, or a placeholder
    /// if the widget ID is unknown (e.g. after removing a widget type).
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
