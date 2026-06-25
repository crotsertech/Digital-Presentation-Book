import SwiftUI

/// Every registrable interactive widget conforms to this. Widgets stay
/// stateless about their document position. They only know how to render
/// and react to user interaction.
@MainActor
protocol SlideWidget {
    /// Stable identifier persisted in the manifest.
    static var widgetID: String { get }

    static var displayName: String { get }
    static var summary: String { get }
    static var iconSystemName: String { get }

    static var defaultParameters: [String: WidgetParameterValue] { get }

    @ViewBuilder
    static func makeView(parameters: [String: WidgetParameterValue]) -> AnyView
}

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
