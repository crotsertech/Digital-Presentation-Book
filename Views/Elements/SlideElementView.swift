//
//  SlideElementView.swift
//  Digital Presentation Book
//
//  Renders a single SlideElement inside a slide canvas. Frame conversion
//  from normalized coordinates happens in `SlideCanvas`, so this view only
//  needs to render the element's content at its bounds.
//

import SwiftUI
import AVKit

struct SlideElementView: View {
    let element: SlideElement
    let package: DPBPackage

    var body: some View {
        contentView
            .opacity(element.opacity)
            .rotationEffect(.degrees(element.rotationDegrees))
    }

    @ViewBuilder
    private var contentView: some View {
        switch element.content {
        case .text(let data):
            TextElementRenderer(data: data)
        case .image(let data):
            ImageElementRenderer(data: data, package: package)
        case .video(let data):
            VideoElementRenderer(data: data, package: package)
        case .shape(let data):
            ShapeElementRenderer(data: data)
        case .widget(let data):
            WidgetRegistry.render(data)
        }
    }
}

// MARK: - Text

private struct TextElementRenderer: View {
    let data: TextElementData

    var body: some View {
        Text(data.string)
            .font(.system(size: data.fontSize, weight: weight))
            .foregroundStyle(data.color.color)
            .multilineTextAlignment(textAlignment)
            .lineSpacing(data.lineSpacing)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
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

// MARK: - Image

private struct ImageElementRenderer: View {
    let data: ImageElementData
    let package: DPBPackage

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
        .clipShape(RoundedRectangle(cornerRadius: data.cornerRadius))
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

// MARK: - Video

private struct VideoElementRenderer: View {
    let data: VideoElementData
    let package: DPBPackage

    @State private var player: AVPlayer?

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
        .onDisappear { player?.pause() }
    }

    private func configurePlayer() {
        let url = package.url(for: data.asset)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        let p = AVPlayer(url: url)
        p.isMuted = data.muted
        if data.autoplay { p.play() }
        if data.loops {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in
                p.seek(to: .zero)
                p.play()
            }
        }
        player = p
    }
}

// MARK: - Shape

private struct ShapeElementRenderer: View {
    let data: ShapeElementData

    var body: some View {
        shape
            .fill(data.fill.color)
            .overlay {
                if let stroke = data.stroke {
                    shape.stroke(stroke.color, lineWidth: data.strokeWidth)
                }
            }
    }

    @ViewBuilder
    private var shape: some Shape {
        switch data.kind {
        case .rectangle:
            Rectangle()
        case .ellipse:
            Ellipse()
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: data.cornerRadius)
        }
    }
}
