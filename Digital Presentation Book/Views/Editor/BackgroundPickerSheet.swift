import SwiftUI

struct BackgroundPickerSheet: View {
    let book: Book
    let currentBackground: SlideBackground
    var onSelectPreset: (BackgroundPreset) -> Void
    var onUploadImage: () -> Void
    var onChooseExistingImage: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var hasReusableImages: Bool {
        for slide in book.allSlides {
            if case .image = slide.background { return true }
            if slide.elements.contains(where: {
                if case .image = $0.content { return true } else { return false }
            }) {
                return true
            }
        }
        return false
    }

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

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Photo", systemImage: "photo.on.rectangle.angled")

            if hasReusableImages {
                photoRow(
                    title: "Reuse image from this book…",
                    subtitle: "Pick from images you've already added. No re-upload needed.",
                    systemImage: "rectangle.stack",
                    tint: .teal
                ) {
                    onChooseExistingImage()
                    dismiss()
                }
            }

            photoRow(
                title: "Choose photo from Files…",
                subtitle: "The image is copied into the .dpb package so it stays available offline.",
                systemImage: "square.and.arrow.up",
                tint: .indigo
            ) {
                onUploadImage()
                dismiss()
            }
        }
    }

    private func photoRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(tint, in: RoundedRectangle(cornerRadius: 9))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
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

    private func matches(_ preset: BackgroundPreset) -> Bool {
        preset.makeBackground(book: book) == currentBackground
    }
}

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
