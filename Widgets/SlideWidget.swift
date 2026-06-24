//
//  SlideWidget.swift
//  Digital Presentation Book
//
//  Protocol every interactive widget conforms to. A widget is identified by
//  a string ID (stored in the manifest) and renders a SwiftUI view given
//  the parameter dictionary saved with the element.
//

import SwiftUI

/// A registrable interactive widget. Widgets stay stateless about their
/// document position — they only know how to render and react to user
/// interaction.
@MainActor
protocol SlideWidget {
    /// Stable identifier persisted in the document manifest.
    static var widgetID: String { get }

    /// Display name shown in the editor's widget picker.
    static var displayName: String { get }

    /// Short description shown alongside `displayName` in the picker.
    static var summary: String { get }

    /// SF Symbol used as the picker icon.
    static var iconSystemName: String { get }

    /// Default parameter values used when the widget is first inserted.
    static var defaultParameters: [String: WidgetParameterValue] { get }

    /// Render the widget's view from a parameter dictionary.
    @ViewBuilder
    static func makeView(parameters: [String: WidgetParameterValue]) -> AnyView
}

/// Read helpers — keep the call sites in widget views readable.
extension Dictionary where Key == String, Value == WidgetParameterValue {
    func string(_ key: String, default defaultValue: String = "") -> String {
        if case .string(let v) = self[key] { return v }
        return defaultValue
    }

    func number(_ key: String, default defaultValue: Double = 0) -> Double {
        if case .number(let v) = self[key] { return v }
        return defaultValue
    }

    func bool(_ key: String, default defaultValue: Bool = false) -> Bool {
        if case .bool(let v) = self[key] { return v }
        return defaultValue
    }

    func stringList(_ key: String, default defaultValue: [String] = []) -> [String] {
        if case .stringList(let v) = self[key] { return v }
        return defaultValue
    }
}
