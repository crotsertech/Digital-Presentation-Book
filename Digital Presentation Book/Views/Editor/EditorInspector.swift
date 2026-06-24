//
//  EditorInspector.swift
//  Digital Presentation Book
//
//  Properties panel shown to the right of the canvas when an element is
//  selected. Each section is bound directly to the selected element so
//  edits live-preview on the canvas without explicit "Apply".
//

import SwiftUI

struct EditorInspector: View {
    @Binding var element: SlideElement
    let book: Book
    var onDelete: () -> Void

    var body: some View {
        Form {
            headerSection
            layoutSection
            typeSpecificSection
            dangerSection
        }
        .formStyle(.grouped)
        .navigationTitle("Inspector")
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: typeIconName)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(typeIconTint, in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 2) {
                    Text(typeDisplayName)
                        .font(.headline)
                    Text("ID \(element.id.uuidString.prefix(8))")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Layout

    private var layoutSection: some View {
        Section("Layout") {
            percentSlider(
                title: "X",
                value: $element.frame.x,
                in: -0.5...1.0
            )
            percentSlider(
                title: "Y",
                value: $element.frame.y,
                in: -0.5...1.0
            )
            percentSlider(
                title: "Width",
                value: $element.frame.width,
                in: 0.03...1.0
            )
            percentSlider(
                title: "Height",
                value: $element.frame.height,
                in: 0.03...1.0
            )

            HStack {
                Text("Rotation")
                Spacer()
                Text("\(Int(element.rotationDegrees))°")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.rotationDegrees, in: -180...180, step: 1)

            HStack {
                Text("Opacity")
                Spacer()
                Text("\(Int(element.opacity * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $element.opacity, in: 0...1)

            Toggle("Lock element", isOn: $element.locked)
        }
    }

    // MARK: - Type-specific

    @ViewBuilder
    private var typeSpecificSection: some View {
        switch element.content {
        case .text:
            if let binding = textBinding {
                TextInspectorSection(data: binding)
            }
        case .shape:
            if let binding = shapeBinding {
                ShapeInspectorSection(data: binding)
            }
        case .image:
            if let binding = imageBinding {
                ImageInspectorSection(data: binding)
            }
        case .video:
            if let binding = videoBinding {
                VideoInspectorSection(data: binding)
            }
        case .widget:
            if let binding = widgetBinding {
                WidgetInspectorSection(data: binding)
            }
        }
    }

    // MARK: - Danger

    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete element", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func percentSlider(
        title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>
    ) -> some View {
        HStack {
            Text(title).frame(width: 60, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .frame(width: 48, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }

    private var typeIconName: String {
        switch element.content {
        case .text:   return "textformat"
        case .image:  return "photo"
        case .video:  return "play.rectangle"
        case .shape:  return "square.on.square"
        case .widget: return "puzzlepiece.extension"
        }
    }

    private var typeIconTint: Color {
        switch element.content {
        case .text:   return .blue
        case .image:  return .green
        case .video:  return .red
        case .shape:  return .orange
        case .widget: return .purple
        }
    }

    private var typeDisplayName: String {
        switch element.content {
        case .text:   return "Text"
        case .image:  return "Image"
        case .video:  return "Video"
        case .shape:  return "Shape"
        case .widget: return "Widget"
        }
    }

    // MARK: - Bindings into the discriminated content enum

    private var textBinding: Binding<TextElementData>? {
        guard case .text(let data) = element.content else { return nil }
        return Binding(
            get: { data },
            set: { element.content = .text($0) }
        )
    }

    private var shapeBinding: Binding<ShapeElementData>? {
        guard case .shape(let data) = element.content else { return nil }
        return Binding(
            get: { data },
            set: { element.content = .shape($0) }
        )
    }

    private var imageBinding: Binding<ImageElementData>? {
        guard case .image(let data) = element.content else { return nil }
        return Binding(
            get: { data },
            set: { element.content = .image($0) }
        )
    }

    private var videoBinding: Binding<VideoElementData>? {
        guard case .video(let data) = element.content else { return nil }
        return Binding(
            get: { data },
            set: { element.content = .video($0) }
        )
    }

    private var widgetBinding: Binding<WidgetElementData>? {
        guard case .widget(let data) = element.content else { return nil }
        return Binding(
            get: { data },
            set: { element.content = .widget($0) }
        )
    }
}

// MARK: - Text

private struct TextInspectorSection: View {
    @Binding var data: TextElementData

    var body: some View {
        Section("Text") {
            TextField("Content", text: $data.string, axis: .vertical)
                .lineLimit(3...8)

            HStack {
                Text("Size")
                Spacer()
                Text("\(Int(data.fontSize)) pt")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $data.fontSize, in: 8...160, step: 1)

            Picker("Weight", selection: $data.fontWeight) {
                ForEach([TextElementData.TextWeight.regular, .medium, .semibold, .bold, .heavy], id: \.self) {
                    Text($0.displayName).tag($0)
                }
            }

            Picker("Alignment", selection: $data.alignment) {
                Label("Leading",  systemImage: "text.alignleft").tag(TextElementData.TextAlignment.leading)
                Label("Center",   systemImage: "text.aligncenter").tag(TextElementData.TextAlignment.center)
                Label("Trailing", systemImage: "text.alignright").tag(TextElementData.TextAlignment.trailing)
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Line spacing")
                Spacer()
                Text("\(Int(data.lineSpacing)) pt")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $data.lineSpacing, in: 0...32, step: 1)

            ColorPicker("Color", selection: rgbaBinding($data.color), supportsOpacity: true)
        }
    }
}

private extension TextElementData.TextWeight {
    var displayName: String {
        switch self {
        case .regular:  return "Regular"
        case .medium:   return "Medium"
        case .semibold: return "Semibold"
        case .bold:     return "Bold"
        case .heavy:    return "Heavy"
        }
    }
}

// MARK: - Shape

private struct ShapeInspectorSection: View {
    @Binding var data: ShapeElementData
    @State private var hasStroke: Bool = false

    var body: some View {
        Section("Shape") {
            Picker("Kind", selection: $data.kind) {
                Label("Rectangle", systemImage: "rectangle").tag(ShapeElementData.ShapeKind.rectangle)
                Label("Rounded",   systemImage: "rectangle.roundedtop").tag(ShapeElementData.ShapeKind.roundedRectangle)
                Label("Ellipse",   systemImage: "circle").tag(ShapeElementData.ShapeKind.ellipse)
            }

            if data.kind == .roundedRectangle {
                HStack {
                    Text("Corner radius")
                    Spacer()
                    Text("\(Int(data.cornerRadius))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $data.cornerRadius, in: 0...80, step: 1)
            }

            ColorPicker("Fill", selection: rgbaBinding($data.fill), supportsOpacity: true)

            Toggle("Stroke", isOn: Binding(
                get: { data.stroke != nil },
                set: { isOn in
                    if isOn && data.stroke == nil {
                        data.stroke = RGBAColor(white: 0)
                        if data.strokeWidth == 0 { data.strokeWidth = 2 }
                    } else if !isOn {
                        data.stroke = nil
                    }
                }
            ))

            if data.stroke != nil {
                ColorPicker("Stroke color", selection: rgbaBinding(Binding(
                    get: { data.stroke ?? RGBAColor(white: 0) },
                    set: { data.stroke = $0 }
                )), supportsOpacity: true)

                HStack {
                    Text("Stroke width")
                    Spacer()
                    Text("\(Int(data.strokeWidth))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Slider(value: $data.strokeWidth, in: 0...20, step: 1)
            }
        }
    }
}

// MARK: - Image

private struct ImageInspectorSection: View {
    @Binding var data: ImageElementData

    var body: some View {
        Section("Image") {
            LabeledContent("Source") {
                Text(data.asset.originalName)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Picker("Fill", selection: $data.fill) {
                Text("Aspect Fit").tag(ImageFill.aspectFit)
                Text("Aspect Fill").tag(ImageFill.aspectFill)
                Text("Stretch").tag(ImageFill.stretch)
            }

            HStack {
                Text("Corner radius")
                Spacer()
                Text("\(Int(data.cornerRadius))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $data.cornerRadius, in: 0...120, step: 1)
        }
    }
}

// MARK: - Video

private struct VideoInspectorSection: View {
    @Binding var data: VideoElementData

    var body: some View {
        Section("Video") {
            LabeledContent("Source") {
                Text(data.asset.originalName)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Toggle("Autoplay", isOn: $data.autoplay)
            Toggle("Loop", isOn: $data.loops)
            Toggle("Muted", isOn: $data.muted)
            Toggle("Show controls", isOn: $data.showsControls)
        }
    }
}

// MARK: - Widget

private struct WidgetInspectorSection: View {
    @Binding var data: WidgetElementData

    var body: some View {
        Section("Widget") {
            if let widget = WidgetRegistry.widget(forID: data.widgetID) {
                LabeledContent("Type") {
                    Text(widget.displayName).font(.subheadline.weight(.medium))
                }
                Text(widget.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent("Type") {
                    Text("Unknown")
                        .foregroundStyle(.orange)
                }
            }

            LabeledContent("ID") {
                Text(data.widgetID)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Parameter editing is widget-specific — full editor lands in
            // a future slice. For now we surface a read-only summary.
            if data.parameters.isEmpty {
                Text("No configurable parameters.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(data.parameters.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key).font(.caption.monospaced())
                        Spacer()
                        Text(describe(data.parameters[key]))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
    }

    private func describe(_ value: WidgetParameterValue?) -> String {
        switch value {
        case .string(let s):       return "\"\(s)\""
        case .number(let n):       return String(format: "%g", n)
        case .bool(let b):         return b ? "true" : "false"
        case .stringList(let arr): return "[\(arr.count)]"
        case .none:                return "—"
        }
    }
}

// MARK: - Color binding helper

/// Bridges a `RGBAColor` field (Codable, sRGB scalars) to SwiftUI's
/// platform `Color` type used by `ColorPicker`. Round-trips through
/// `CGColor` so we preserve the picker's opacity choice.
private func rgbaBinding(_ source: Binding<RGBAColor>) -> Binding<Color> {
    Binding(
        get: { source.wrappedValue.color },
        set: { newColor in
            let resolved = newColor.resolve(in: .init())
            source.wrappedValue = RGBAColor(
                red: Double(resolved.red),
                green: Double(resolved.green),
                blue: Double(resolved.blue),
                alpha: Double(resolved.opacity)
            )
        }
    )
}
