//
//  EditorSlideList.swift
//  Digital Presentation Book
//
//  Sidebar for the editor — ordered list of every slide grouped by chapter.
//  Tapping a slide selects it; swipes and the chapter-header menu provide
//  add / delete / rename for chapters and slides. Mutations happen against
//  the bound `Book` directly so the canvas updates live.
//

import SwiftUI

struct EditorSlideList: View {
    @Binding var book: Book
    @Binding var currentSlideID: UUID?

    /// Drives the rename alert. When non-nil, the alert is presented and
    /// the draft text holds the in-progress title.
    @State private var renamingChapter: Chapter?
    @State private var renameDraft: String = ""

    var body: some View {
        List {
            ForEach(book.chapters) { chapter in
                chapterSection(chapter)
            }

            Section {
                Button {
                    addChapter()
                } label: {
                    Label("Add Chapter", systemImage: "folder.badge.plus")
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .listStyle(.sidebar)
        .alert(
            "Rename Chapter",
            isPresented: Binding(
                get: { renamingChapter != nil },
                set: { if !$0 { renamingChapter = nil } }
            )
        ) {
            TextField("Chapter title", text: $renameDraft)
            Button("Cancel", role: .cancel) {
                renamingChapter = nil
            }
            Button("Rename") {
                commitRename()
            }
        }
    }

    // MARK: - Sections

    private func chapterSection(_ chapter: Chapter) -> some View {
        Section {
            ForEach(Array(chapter.slides.enumerated()), id: \.element.id) { idx, slide in
                slideRow(chapter: chapter, slide: slide, index: idx)
            }

            Button {
                addSlide(toChapterID: chapter.id)
            } label: {
                Label("Add Slide", systemImage: "plus")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        } header: {
            chapterHeader(chapter)
        }
    }

    private func slideRow(chapter: Chapter, slide: Slide, index: Int) -> some View {
        Button {
            currentSlideID = slide.id
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 22, alignment: .trailing)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(slide.title.isEmpty ? "Untitled slide" : slide.title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                    Text("\(slide.elements.count) element\(slide.elements.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
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
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteSlide(id: slide.id, in: chapter.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                deleteSlide(id: slide.id, in: chapter.id)
            } label: {
                Label("Delete Slide", systemImage: "trash")
            }
        }
    }

    private func chapterHeader(_ chapter: Chapter) -> some View {
        HStack(spacing: 6) {
            if let accent = chapter.accentColor?.color {
                Circle().fill(accent).frame(width: 8, height: 8)
            }
            Text(chapter.title.isEmpty ? "Untitled chapter" : chapter.title)
                .font(.headline)
            Spacer()
            Menu {
                Button {
                    startRename(chapter)
                } label: {
                    Label("Rename Chapter", systemImage: "pencil")
                }
                Button {
                    addSlide(toChapterID: chapter.id)
                } label: {
                    Label("Add Slide", systemImage: "plus")
                }
                Divider()
                Button(role: .destructive) {
                    deleteChapter(id: chapter.id)
                } label: {
                    Label("Delete Chapter", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
                    .imageScale(.medium)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    // MARK: - Mutations

    private func startRename(_ chapter: Chapter) {
        renameDraft = chapter.title
        renamingChapter = chapter
    }

    private func commitRename() {
        guard let chapter = renamingChapter,
              let idx = book.chapters.firstIndex(where: { $0.id == chapter.id }) else {
            renamingChapter = nil
            return
        }
        let trimmed = renameDraft.trimmingCharacters(in: .whitespaces)
        book.chapters[idx].title = trimmed.isEmpty ? "Untitled chapter" : trimmed
        renamingChapter = nil
    }

    private func addSlide(toChapterID chapterID: UUID) {
        guard let idx = book.chapters.firstIndex(where: { $0.id == chapterID }) else { return }
        let slide = Slide(title: "")
        book.chapters[idx].slides.append(slide)
        currentSlideID = slide.id
    }

    /// Reroutes `currentSlideID` to a nearby slide before mutating the array
    /// so the inspector / canvas don't briefly bind to a vanished slide.
    private func deleteSlide(id slideID: UUID, in chapterID: UUID) {
        guard let chapterIdx = book.chapters.firstIndex(where: { $0.id == chapterID }) else { return }
        guard let slideIdx = book.chapters[chapterIdx].slides.firstIndex(where: { $0.id == slideID }) else { return }

        if currentSlideID == slideID {
            let chapter = book.chapters[chapterIdx]
            let neighborInChapter = chapter.slides.indices
                .first(where: { $0 != slideIdx })
                .map { chapter.slides[$0].id }
            currentSlideID = neighborInChapter
                ?? book.allSlides.first(where: { $0.id != slideID })?.id
        }
        book.chapters[chapterIdx].slides.remove(at: slideIdx)
    }

    private func addChapter() {
        let chapter = Chapter(title: "New Chapter", slides: [Slide(title: "")])
        book.chapters.append(chapter)
        currentSlideID = chapter.slides.first?.id
    }

    private func deleteChapter(id chapterID: UUID) {
        guard let chapterIdx = book.chapters.firstIndex(where: { $0.id == chapterID }) else { return }
        let removedSlideIDs = Set(book.chapters[chapterIdx].slides.map { $0.id })
        book.chapters.remove(at: chapterIdx)
        if let currentID = currentSlideID, removedSlideIDs.contains(currentID) {
            currentSlideID = book.allSlides.first?.id
        }
    }
}
