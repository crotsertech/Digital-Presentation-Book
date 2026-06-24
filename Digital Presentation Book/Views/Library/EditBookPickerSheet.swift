//
//  EditBookPickerSheet.swift
//  Digital Presentation Book
//
//  Modal sheet for the "Edit Book" tile. Lists every existing book; the
//  caller routes the chosen book into the editor.
//
//  Skipped when the library is empty (caller offers creation instead) or
//  when there's exactly one book (caller opens it directly).
//

import SwiftUI

struct EditBookPickerSheet: View {
    let books: [Book]
    var onSelect: (Book) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(books) { book in
                Button {
                    onSelect(book)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        LinearGradient(
                            colors: [book.theme.primaryColor.color, book.theme.secondaryColor.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 64, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text("\(book.allSlides.count) slide\(book.allSlides.count == 1 ? "" : "s") • Updated \(book.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                        Image(systemName: "pencil")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Edit a Book")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
