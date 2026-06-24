//
//  BackgroundPickerSheet.swift
//  Digital Presentation Book
//
//  Modal that lets the user swap the current slide's background. Offers
//  curated water-themed presets (gradients + solids) and a "Choose Photo"
//  option that triggers an image file picker handled by the editor.
//

import SwiftUI

struct BackgroundPickerSheet: View {
    let book: Book
    let currentBackground: SlideBackground
    var onSelectPreset: (BackgroundPreset) -> Void
    var onUploadImage: () -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    photoSection
                    presetsSection
                }
                .padding(16)
            }
            .navigationTitle("Slide Background")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Photo", systemImage: "photo.on.rectangle.angled")
            Button {
                onUploadImage()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.indigo, in: RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose photo from Files…")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("The image is copied into the .dpb package so it stays available offline.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Presets", systemImage: "paintpalette.fill")
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(BackgroundPreset.allCases) { preset in
                    PresetCard(
                        preset: preset,
                        book: book,
                        isCurrent: matches(preset)
                    ) {
                        onSelectPreset(preset)
                        dismiss()
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    /// Best-effort: does the currently selected preset produce the slide's
    /// current background? Used to mark the "current" card with a check.
    private func matches(_ preset: BackgroundPreset) -> Bool {
        preset.makeBackground(book: book) == currentBackground
    }
}

// MARK: - Card

private struct PresetCard: View {
    let preset: BackgroundPreset
    let book: Book
    let isCurrent: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                preview
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(.quaternary, lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if isCurrent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, .tint)
                                .font(.title3)
                                .shadow(color: .black.opacity(0.25), radius: 2)
                                .padding(6)
                        }
                    }
                VStack(alignment: .leading, spacing: 1) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(preset.summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var preview: some View {
        switch preset.makeBackground(book: book) {
        case .themeDefault:
            book.theme.backgroundColor.color
        case .solid(let color):
            color.color
        case .gradient(let start, let end, let angle):
            LinearGradient(
                colors: [start.color, end.color],
                startPoint: unitPoint(start: angle),
                endPoint: unitPoint(end: angle)
            )
        case .image:
            book.theme.backgroundColor.color
        }
    }

    private func unitPoint(start angleDegrees: Double) -> UnitPoint {
        let radians = angleDegrees * .pi / 180
        return UnitPoint(x: 0.5 - cos(radians) * 0.5, y: 0.5 - sin(radians) * 0.5)
    }

    private func unitPoint(end angleDegrees: Double) -> UnitPoint {
        let radians = angleDegrees * .pi / 180
        return UnitPoint(x: 0.5 + cos(radians) * 0.5, y: 0.5 + sin(radians) * 0.5)
    }
}
