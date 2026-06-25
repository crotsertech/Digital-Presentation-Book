import SwiftUI

struct SlideCanvas: View {
    let slide: Slide
    let book: Book
    let package: DPBPackage

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = canvasSize(in: proxy.size)
            let scale = canvasSize.height / book.aspectRatio.nominalSize.height
            ZStack {
                backgroundView
                ForEach(slide.elements) { element in
                    let rect = element.frame.cgRect(in: canvasSize)
                    SlideElementView(element: element, package: package, canvasScale: scale)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
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

    /// Largest rectangle of `book.aspectRatio` that fits in `available`,
    /// used to letterbox the slide inside the player.
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
