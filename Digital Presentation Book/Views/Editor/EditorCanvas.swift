import SwiftUI

// Editable counterpart to SlideCanvas. Elements are positioned with
// `.offset` (not `.position`) so each one's hit target stays at its own
// bounds. Otherwise every element would absorb taps across the whole
// canvas and selection would be unusable.

struct EditorCanvas: View {
    @Binding var slide: Slide
    let book: Book
    let package: DPBPackage
    @Binding var selectedElementID: UUID?

    /// Stored in normalized canvas coords so the guide overlay scales
    /// correctly when the canvas is resized.
    @State private var snapGuides: SnapGuides?

    var body: some View {
        GeometryReader { proxy in
            let canvas = canvasSize(in: proxy.size)
            let scale = canvas.height / book.aspectRatio.nominalSize.height
            HStack {
                Spacer(minLength: 0)
                VStack {
                    Spacer(minLength: 0)
                    canvasContent(size: canvas, scale: scale)
                        .frame(width: canvas.width, height: canvas.height)
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func canvasContent(size: CGSize, scale: CGFloat) -> some View {
        let allElements = slide.elements
        return ZStack(alignment: .topLeading) {
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
                    canvasScale: scale,
                    package: package,
                    isSelected: selectedElementID == element.id,
                    siblings: allElements.filter { $0.id != element.id },
                    onSelect: { selectedElementID = element.id },
                    onSnapUpdate: { snapGuides = $0 }
                )
                .frame(width: rect.width, height: rect.height)
                .offset(x: rect.minX, y: rect.minY)
            }

            if let guides = snapGuides {
                snapOverlay(guides: guides, canvasSize: size)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .overlay(alignment: .bottomTrailing) {
            Text("\(Int(size.width)) × \(Int(size.height)) • iPad nominal \(Int(book.aspectRatio.nominalSize.width))×\(Int(book.aspectRatio.nominalSize.height))")
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

    @ViewBuilder
    private func snapOverlay(guides: SnapGuides, canvasSize size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(guides.verticals, id: \.self) { x in
                Rectangle()
                    .fill(Color.pink)
                    .frame(width: 1, height: size.height)
                    .offset(x: x * size.width)
            }
            ForEach(guides.horizontals, id: \.self) { y in
                Rectangle()
                    .fill(Color.pink)
                    .frame(width: size.width, height: 1)
                    .offset(y: y * size.height)
            }
        }
        .allowsHitTesting(false)
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

/// Wraps a `SlideElementView` with selection halo, resize handles, and a
/// drag gesture. Gestures are scoped to the element's own bounds so taps on
/// empty canvas fall through to the deselect handler.
private struct EditableElementView: View {
    @Binding var element: SlideElement
    let canvasSize: CGSize
    let canvasScale: CGFloat
    let package: DPBPackage
    let isSelected: Bool
    let siblings: [SlideElement]
    let onSelect: () -> Void
    let onSnapUpdate: (SnapGuides?) -> Void

    /// Anchored to the frame at gesture-start so deltas don't compound
    /// against the live frame mid-drag.
    @State private var dragStartFrame: NormalizedRect?

    var body: some View {
        ZStack {
            SlideElementView(element: element, package: package, canvasScale: canvasScale)
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
                // Clamp is generous so off-canvas bleed placement still
                // works, but bounded so a wild fling can't fly to infinity.
                let rawX = clamp(start.x + dxN, min: -2.0, max: 2.0)
                let rawY = clamp(start.y + dyN, min: -2.0, max: 2.0)
                let snapped = snapMove(
                    x: rawX, y: rawY,
                    width: start.width, height: start.height,
                    siblings: siblings,
                    canvasSize: canvasSize
                )
                element.frame.x = snapped.x
                element.frame.y = snapped.y
                onSnapUpdate(snapped.guides.isEmpty ? nil : snapped.guides)
            }
            .onEnded { _ in
                dragStartFrame = nil
                onSnapUpdate(nil)
            }
    }
}

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
        // Spill the handles outside the element so they remain grabbable
        // when the element is small.
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

/// Vertical and horizontal alignment lines, in normalized canvas coords.
struct SnapGuides: Equatable {
    var verticals: [Double] = []
    var horizontals: [Double] = []

    var isEmpty: Bool { verticals.isEmpty && horizontals.isEmpty }
}

private struct SnappedMove {
    var x: Double
    var y: Double
    var guides: SnapGuides
}

/// Snaps the moving element's leading/center/trailing and top/center/bottom
/// edges to the canvas edges/center and to sibling element edges, within a
/// few-point pixel threshold. Returns the adjusted x/y plus guide lines so
/// the canvas overlay can show which edge is aligning.
private func snapMove(
    x: Double, y: Double,
    width: Double, height: Double,
    siblings: [SlideElement],
    canvasSize: CGSize,
    thresholdPt: CGFloat = 6
) -> SnappedMove {
    let thresholdX = Double(thresholdPt) / Double(canvasSize.width)
    let thresholdY = Double(thresholdPt) / Double(canvasSize.height)

    var xTargets: [Double] = [0, 0.5, 1.0]
    var yTargets: [Double] = [0, 0.5, 1.0]
    for s in siblings {
        let f = s.frame
        xTargets.append(contentsOf: [f.x, f.x + f.width / 2, f.x + f.width])
        yTargets.append(contentsOf: [f.y, f.y + f.height / 2, f.y + f.height])
    }

    let myXs = [x, x + width / 2, x + width]
    let myYs = [y, y + height / 2, y + height]

    let xBest = closestSnap(myEdges: myXs, targets: xTargets, threshold: thresholdX)
    let yBest = closestSnap(myEdges: myYs, targets: yTargets, threshold: thresholdY)

    var guides = SnapGuides()
    var newX = x, newY = y
    if let xBest {
        newX = x + xBest.delta
        guides.verticals = [xBest.target]
    }
    if let yBest {
        newY = y + yBest.delta
        guides.horizontals = [yBest.target]
    }
    return SnappedMove(x: newX, y: newY, guides: guides)
}

private struct SnapHit {
    var delta: Double
    var target: Double
}

private func closestSnap(myEdges: [Double], targets: [Double], threshold: Double) -> SnapHit? {
    var best: SnapHit?
    for edge in myEdges {
        for target in targets {
            let delta = target - edge
            if abs(delta) <= threshold {
                if best == nil || abs(delta) < abs(best!.delta) {
                    best = SnapHit(delta: delta, target: target)
                }
            }
        }
    }
    return best
}

private func clamp(_ value: Double, min lo: Double, max hi: Double) -> Double {
    Swift.min(Swift.max(value, lo), hi)
}
