import SwiftUI
import AVKit

struct SlideElementView: View {
    let element: SlideElement
    let package: DPBPackage
    /// Multiplier the parent canvas applies to absolute-point fields (font
    /// size, stroke width, corner radius, line spacing). Computed as
    /// `actualCanvasHeight / aspectRatio.nominalSize.height`, so a book
    /// designed at the iPad's 1024×768 looks the same on any display.
    var canvasScale: CGFloat = 1.0

    var body: some View {
        contentView
            .opacity(element.opacity)
            .rotationEffect(.degrees(element.rotationDegrees))
    }

    @ViewBuilder
    private var contentView: some View {
        switch element.content {
        case .text(let data):
            TextElementRenderer(data: data, canvasScale: canvasScale)
        case .image(let data):
            ImageElementRenderer(data: data, package: package, canvasScale: canvasScale)
        case .video(let data):
            VideoElementRenderer(data: data, package: package)
        case .shape(let data):
            ShapeElementRenderer(data: data, canvasScale: canvasScale)
        case .widget(let data):
            WidgetRegistry.render(data)
        }
    }
}

private struct TextElementRenderer: View {
    let data: TextElementData
    let canvasScale: CGFloat

    var body: some View {
        Text(data.string)
            .font(font)
            .fontWeight(weight)
            .foregroundStyle(data.color.color)
            .multilineTextAlignment(textAlignment)
            .lineSpacing(data.lineSpacing * canvasScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
    }

    private var font: Font {
        FontCatalog.font(family: data.fontFamily, size: data.fontSize * canvasScale)
    }

    private var weight: Font.Weight {
        switch data.fontWeight {
        case .regular:  return .regular
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        case .heavy:    return .heavy
        }
    }

    private var textAlignment: TextAlignment {
        switch data.alignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch data.alignment {
        case .leading:  return .topLeading
        case .center:   return .center
        case .trailing: return .topTrailing
        }
    }
}

private struct ImageElementRenderer: View {
    let data: ImageElementData
    let package: DPBPackage
    let canvasScale: CGFloat

    var body: some View {
        let url = package.url(for: data.asset)
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(symbol: "photo.badge.exclamationmark")
            case .empty:
                placeholder(symbol: "photo")
            @unknown default:
                placeholder(symbol: "photo")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: data.cornerRadius * canvasScale))
    }

    private var contentMode: ContentMode {
        switch data.fill {
        case .aspectFit:  return .fit
        case .aspectFill: return .fill
        case .stretch:    return .fill
        }
    }

    private func placeholder(symbol: String) -> some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

private struct VideoElementRenderer: View {
    let data: VideoElementData
    let package: DPBPackage

    @State private var player: AVPlayer?
    /// Held so we can remove it on teardown or when the user turns loop
    /// off. Leaving it leaks and keeps restarting the player after the
    /// view goes away.
    @State private var loopObserver: NSObjectProtocol?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                Rectangle()
                    .fill(.black)
                    .overlay(
                        Image(systemName: "video.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.white.opacity(0.6))
                    )
            }
        }
        .onAppear { configurePlayer() }
        .onChange(of: data.asset) { _, _ in configurePlayer() }
        .onChange(of: data.muted) { _, newValue in player?.isMuted = newValue }
        .onChange(of: data.loops) { _, newValue in updateLoopObserver(enabled: newValue) }
        .onChange(of: data.autoplay) { _, newValue in
            if newValue { player?.play() }
        }
        .onDisappear {
            player?.pause()
            removeLoopObserver()
        }
    }

    private func configurePlayer() {
        removeLoopObserver()
        let url = package.url(for: data.asset)
        guard FileManager.default.fileExists(atPath: url.path) else {
            player = nil
            return
        }
        let p = AVPlayer(url: url)
        p.isMuted = data.muted
        if data.autoplay { p.play() }
        player = p
        updateLoopObserver(enabled: data.loops)
    }

    private func updateLoopObserver(enabled: Bool) {
        removeLoopObserver()
        guard enabled, let p = player else { return }
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: p.currentItem,
            queue: .main
        ) { _ in
            p.seek(to: .zero)
            p.play()
        }
    }

    private func removeLoopObserver() {
        if let token = loopObserver {
            NotificationCenter.default.removeObserver(token)
            loopObserver = nil
        }
    }
}

private struct ShapeElementRenderer: View {
    let data: ShapeElementData
    let canvasScale: CGFloat

    var body: some View {
        shape
            .fill(data.fill.color)
            .overlay {
                if let stroke = data.stroke {
                    shape.stroke(stroke.color, lineWidth: data.strokeWidth * canvasScale)
                }
            }
    }

    private var shape: AnyShape {
        switch data.kind {
        case .rectangle:
            return AnyShape(Rectangle())
        case .ellipse:
            return AnyShape(Ellipse())
        case .roundedRectangle:
            return AnyShape(RoundedRectangle(cornerRadius: data.cornerRadius * canvasScale))
        }
    }
}
