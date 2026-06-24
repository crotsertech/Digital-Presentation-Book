//
//  BookAssetPicker.swift
//  Digital Presentation Book
//
//  Sheet that surfaces every image (or video) asset already imported into
//  the current book so the rep can reuse it instead of re-uploading. Picking
//  an entry reuses its `AssetReference` — the underlying file in the package
//  is shared, so one logical image can appear on many slides without bloat.
//

import SwiftUI

struct BookAssetPicker: View {
    enum Kind {
        case image
        case video

        var navigationTitle: String {
            switch self {
            case .image: return "Choose Image"
            case .video: return "Choose Video"
            }
        }

        var emptyMessage: String {
            switch self {
            case .image: return "No images in this book yet. Upload one to get started."
            case .video: return "No videos in this book yet. Upload one to get started."
            }
        }

        var uploadLabel: String {
            switch self {
            case .image: return "Upload New Image…"
            case .video: return "Upload New Video…"
            }
        }
    }

    let book: Book
    let package: DPBPackage
    let kind: Kind
    var onSelect: (AssetReference) -> Void
    var onUploadNew: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    uploadCard

                    ForEach(assets, id: \.id) { asset in
                        AssetCard(asset: asset, package: package, kind: kind) {
                            onSelect(asset)
                            dismiss()
                        }
                    }
                }
                .padding(16)

                if assets.isEmpty {
                    Text(kind.emptyMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .background(.background.secondary)
            .navigationTitle(kind.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var uploadCard: some View {
        Button {
            dismiss()
            // Defer so the sheet finishes dismissing before the file
            // importer presents — stacking presentations on the same frame
            // can no-op silently.
            DispatchQueue.main.async {
                onUploadNew()
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.tint.opacity(0.12))
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .aspectRatio(1, contentMode: .fit)

                Text(kind.uploadLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(6)
        }
        .buttonStyle(.plain)
    }

    /// All unique assets of the requested kind referenced anywhere in the
    /// book — slide images, slide backgrounds, and (for video kind) video
    /// elements. Deduplicated by `AssetReference.id`.
    private var assets: [AssetReference] {
        var seen: Set<UUID> = []
        var out: [AssetReference] = []

        func consider(_ asset: AssetReference) {
            if seen.insert(asset.id).inserted {
                out.append(asset)
            }
        }

        for slide in book.allSlides {
            if kind == .image, case .image(let asset, _) = slide.background {
                consider(asset)
            }
            for element in slide.elements {
                switch element.content {
                case .image(let data) where kind == .image:
                    consider(data.asset)
                case .video(let data) where kind == .video:
                    consider(data.asset)
                default:
                    break
                }
            }
        }
        return out
    }
}

private struct AssetCard: View {
    let asset: AssetReference
    let package: DPBPackage
    let kind: BookAssetPicker.Kind
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                thumbnail
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.separator, lineWidth: 0.5)
                    )

                Text(asset.originalName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(6)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnail: some View {
        let fileURL = package.url(for: asset)
        switch kind {
        case .image:
            AsyncImage(url: fileURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty:
                    ZStack {
                        Color(.tertiarySystemBackground)
                        ProgressView()
                    }
                case .failure:
                    placeholder(systemImage: "photo")
                @unknown default:
                    placeholder(systemImage: "photo")
                }
            }
        case .video:
            ZStack {
                Color(.tertiarySystemBackground)
                Image(systemName: "play.rectangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func placeholder(systemImage: String) -> some View {
        ZStack {
            Color(.tertiarySystemBackground)
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
