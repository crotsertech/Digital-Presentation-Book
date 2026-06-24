//
//  EditorCanvas.swift
//  Digital Presentation Book
//
//  Editable version of SlideCanvas. Each element renders at its own frame
//  (positioned via `.offset` from the top-leading corner of the canvas)
//  so hit testing is per-element. Using `.position` would cause every
//  element to occupy the whole canvas as a tap target.
//

import SwiftUI

struct EditorCanvas: View {
    @Binding var slide: Slide
    let book: Book
    let package: DPBPackage
    @Binding var selectedElementID: UUID?

    var body: some View {
        GeometryReader { proxy in
            let canvas = canvasSize(in: proxy.size)
            HStack {
                Spacer(minLength: 0)
                VStack {
                    Spacer(minLength: 0)
                    canvasContent(size: canvas)
                        .frame(width: canvas.width, height: canvas.height)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func canvasContent(size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            background
                .frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedElementID = nil
                }

            ForEach($slide.elements) { $element in
                let rect = element.frame.cgRect(in: size)
                EditableElementView(
                    element: $element,
                    canvasSize: size,
                    package: package,
                    isSelected: selectedElementID == element.id,
                    onSelect: { selectedElementID = element.id }
                )
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.minX, y: rect.minY)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            Text("\(Int(size.width)) × \(Int(size.height))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(6)
                .background(.regularMaterial, in: Capsule())
                .padding(8)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch slide.background {
        case .themeDefault:
            book.theme.backgroundColor.color
        case .solid(let color):
            color.color
        case .gradient(let start, let end, let angle):
            LinearGradient(
                colors: [start.color, end.color],
                startPoint: gradientStart(angle),
                endPoint: gradientEnd(angle)
            )
        case .image(let asset, let fill):
            let url = package.url(for: asset)
            AsyncImage(url: url) { image in
                image.resizable()
                    .aspectRatio(contentMode: fill == .aspectFit ? .fit : .fill)
            } placeholder: {
                book.theme.backgroundColor.color
            }
        }
    }

    private func canvasSize(in available: CGSize) -> CGSize {
        let ratio = book.aspectRatio.ratio
        let widthIfHeightFits = available.height * ratio
        if widthIfHeightFits <= available.width {
            return CGSize(width: widthIfHeightFits, height: available.height)
        } else {
            return CGSize(width: available.width, height: available.width / ratio)
        }
    }

    private func gradientStart(_ angleDegrees: Double) -> UnitPoint {
        let radians = angleDegrees * .pi / 180
        return UnitPoint(x: 0.5 - cos(radians) * 0.5, y: 0.5 - sin(radians) * 0.5)
    }

    private func gradientEnd(_ angleDegrees: Double) -> UnitPoint {
        let radians = angleDegrees * .pi / 180
        return UnitPoint(x: 0.5 + cos(radians) * 0.5, y: 0.5 + sin(radians) * 0.5)
    }
}

// MARK: - Editable element

/// Wraps a `SlideElementView` with interaction overlays: a halo when
/// selected, four corner resize handles, and a drag gesture for moving.
/// The element is sized by its parent — gestures cover only its own
/// bounds so taps on empty canvas area fall through to deselect.
private struct EditableElementView: View {
    @Binding var element: SlideElement
    let canvasSize: CGSize
    let package: DPBPackage
    let isSelected: Bool
    let onSelect: () -> Void

    /// The element's frame at the moment a gesture began. We add deltas to
    /// this rather than the live frame so the motion doesn't compound.
    @State private var dragStartFrame: NormalizedRect?

    var body: some View {
        ZStack {
            SlideElementView(element: element, package: package)
                .allowsHitTesting(false)

            if isSelected {
                Rectangle()
                    .strokeBorder(Color.accentColor, lineWidth: 2)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .gesture(moveGesture)
        .overlay {
            if isSelected {
                ResizeHandles(
                    element: $element,
                    canvasSize: canvasSize
                )
            }
        }
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if !isSelected { onSelect() }
                if dragStartFrame == nil { dragStartFrame = element.frame }
                guard let start = dragStartFrame else { return }
                let dxN = value.translation.width / canvasSize.width
                let dyN = value.translation.height / canvasSize.height
                element.frame.x = clamp(start.x + dxN, min: -start.width * 0.5, max: 1 - start.width * 0.5)
                element.frame.y = clamp(start.y + dyN, min: -start.height * 0.5, max: 1 - start.height * 0.5)
            }
            .onEnded { _ in
                dragStartFrame = nil
            }
    }
}

// MARK: - Resize handles

/// Four corner handles overlaid on top of the selected element.
private struct ResizeHandles: View {
    @Binding var element: SlideElement
    let canvasSize: CGSize

    @State private var startFrame: NormalizedRect?

    private let handleSize: CGFloat = 18
    private let minNormalizedSize: Double = 0.03

    var body: some View {
        ZStack {
            handle(.topLeading)
            handle(.topTrailing)
            handle(.bottomLeading)
            handle(.bottomTrailing)
        }
        // Let the handles spill outside the element's frame so they're
        // easy to grab when the element is small.
        .padding(-handleSize / 2)
    }

    private enum Corner {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    @ViewBuilder
    private func handle(_ corner: Corner) -> some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 2))
            .frame(width: handleSize, height: handleSize)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: corner))
            .contentShape(Rectangle().inset(by: -8))
            .gesture(resizeGesture(corner))
    }

    private func alignment(for corner: Corner) -> Alignment {
        switch corner {
        case .topLeading:     return .topLeading
        case .topTrailing:    return .topTrailing
        case .bottomLeading:  return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }

    private func resizeGesture(_ corner: Corner) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if startFrame == nil { startFrame = element.frame }
                guard let s = startFrame else { return }
                let dxN = value.translation.width / canvasSize.width
                let dyN = value.translation.height / canvasSize.height

                var x = s.x, y = s.y, w = s.width, h = s.height

                switch corner {
                case .topLeading:
                    x = s.x + dxN; w = s.width - dxN
                    y = s.y + dyN; h = s.height - dyN
                case .topTrailing:
                    w = s.width + dxN
                    y = s.y + dyN; h = s.height - dyN
                case .bottomLeading:
                    x = s.x + dxN; w = s.width - dxN
                    h = s.height + dyN
                case .bottomTrailing:
                    w = s.width + dxN
                    h = s.height + dyN
                }

                if w < minNormalizedSize {
                    if corner == .topLeading || corner == .bottomLeading {
                        x = s.x + s.width - minNormalizedSize
                    }
                    w = minNormalizedSize
                }
                if h < minNormalizedSize {
                    if corner == .topLeading || corner == .topTrailing {
                        y = s.y + s.height - minNormalizedSize
                    }
                    h = minNormalizedSize
                }

                element.frame = NormalizedRect(x: x, y: y, width: w, height: h)
            }
            .onEnded { _ in
                startFrame = nil
            }
    }
}

// MARK: - Utility

private func clamp(_ value: Double, min lo: Double, max hi: Double) -> Double {
    Swift.min(Swift.max(value, lo), hi)
}
