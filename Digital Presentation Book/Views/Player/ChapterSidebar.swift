import SwiftUI

struct ChapterSidebar: View {
    let book: Book
    @Binding var currentSlideID: UUID?
    var onSelectSlide: (UUID) -> Void

    var body: some View {
        List {
            ForEach(book.chapters) { chapter in
                let visible = chapter.slides.filter { !$0.isHidden }
                Section {
                    ForEach(Array(visible.enumerated()), id: \.element.id) { idx, slide in
                        Button {
                            onSelectSlide(slide.id)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(idx + 1)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 22, alignment: .trailing)
                                Text(slide.title.isEmpty ? "Untitled slide" : slide.title)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                Spacer(minLength: 0)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            currentSlideID == slide.id
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                    }
                } header: {
                    HStack {
                        if let accent = chapter.accentColor?.color {
                            Circle().fill(accent).frame(width: 8, height: 8)
                        }
                        Text(chapter.title)
                            .font(.headline)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
