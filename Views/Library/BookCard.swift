//
//  BookCard.swift
//  Digital Presentation Book
//
//  Single card in the library grid representing one book.
//

import SwiftUI

struct BookCard: View {
    let book: Book
    var onOpen: () -> Void
    var onExport: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
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
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open", systemImage: "play.fill", action: onOpen)
            Button("Export…", systemImage: "square.and.arrow.up", action: onExport)
            Divider()
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    private var preview: some View {
        ZStack(alignment: .bottomLeading) {
            background
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

    private var background: some View {
        LinearGradient(
            colors: [book.theme.primaryColor.color, book.theme.secondaryColor.color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var metadata: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(book.allSlides.count) slide\(book.allSlides.count == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                Text(book.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
    }
}
