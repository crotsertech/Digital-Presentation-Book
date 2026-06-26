import SwiftUI

struct BookCard: View {
    let book: Book
    let package: DPBPackage
    var onOpen: () -> Void
    var onEdit: () -> Void
    var onExport: () -> Void
    var onDelete: () -> Void
    var onRename: () -> Void
    var onToggleLock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            preview
            metadata
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture { onOpen() }
        .contextMenu {
            Button("Present", systemImage: "play.fill", action: onOpen)
            Button("Edit…", systemImage: "pencil", action: onEdit)
                .disabled(book.isLocked)
            Button(
                book.isLocked ? "Unlock Changes" : "Lock Changes",
                systemImage: book.isLocked ? "lock.open.fill" : "lock.fill",
                action: onToggleLock
            )
            Button("Rename…", systemImage: "character.cursor.ibeam", action: onRename)
            Button("Export…", systemImage: "square.and.arrow.up", action: onExport)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    private var preview: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnail

            // Scrim keeps the title legible regardless of underlying content.
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(book.theme.primaryColor.color)
                        .padding(14)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                        .padding(14)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if !book.subtitle.isEmpty {
                    Text(book.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(14)
        }
        .aspectRatio(book.aspectRatio.ratio, contentMode: .fit)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 18
            )
        )
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let slide = book.presentableSlides.first ?? book.allSlides.first {
            SlideCanvas(slide: slide, book: book, package: package)
                .allowsHitTesting(false)
        } else {
            LinearGradient(
                colors: [book.theme.primaryColor.color, book.theme.secondaryColor.color],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var metadata: some View {
        HStack(spacing: 6) {
            Text("\(book.allSlides.count) slide\(book.allSlides.count == 1 ? "" : "s")")
                .font(.caption.weight(.medium))
            Text("·")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(book.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if book.isLocked {
                Label("Locked", systemImage: "lock.fill")
                    .labelStyle(.iconOnly)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }
}
