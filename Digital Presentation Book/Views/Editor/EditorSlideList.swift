import SwiftUI

struct EditorSlideList: View {
    @Binding var book: Book
    @Binding var currentSlideID: UUID?

    @State private var renamingChapter: Chapter?
    @State private var renameDraft: String = ""

    var body: some View {
        List {
            ForEach(book.chapters) { chapter in
                chapterSection(chapter)
            }
            .onMove(perform: moveChapters)

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

    private func chapterSection(_ chapter: Chapter) -> some View {
        Section {
            ForEach(Array(chapter.slides.enumerated()), id: \.element.id) { idx, slide in
                slideRow(chapter: chapter, slide: slide, index: idx)
            }
            .onMove { source, destination in
                moveSlides(in: chapter.id, from: source, to: destination)
            }

            addSlideControl(forChapter: chapter)
        } header: {
            chapterHeader(chapter)
        }
    }

    /// Plain button when there are no templates; menu with duplicate options when there are.
    @ViewBuilder
    private func addSlideControl(forChapter chapter: Chapter) -> some View {
        let templates = book.allSlides.filter { $0.isTemplate }
        if templates.isEmpty {
            Button {
                addSlide(toChapterID: chapter.id)
            } label: {
                addSlideLabel
            }
            .buttonStyle(.plain)
        } else {
            Menu {
                Button {
                    addSlide(toChapterID: chapter.id)
                } label: {
                    Label("Blank Slide", systemImage: "plus")
                }
                Section("Duplicate from Template") {
                    ForEach(templates) { template in
                        Button {
                            duplicate(template, toChapterID: chapter.id)
                        } label: {
                            Label(
                                template.title.isEmpty ? "Untitled template" : template.title,
                                systemImage: "bookmark.fill"
                            )
                        }
                    }
                }
            } label: {
                addSlideLabel
            }
            .menuStyle(.borderlessButton)
        }
    }

    private var addSlideLabel: some View {
        Label("Add Slide", systemImage: "plus")
            .font(.caption.weight(.medium))
            .foregroundStyle(.tint)
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
                    HStack(spacing: 4) {
                        Text(slide.title.isEmpty ? "Untitled slide" : slide.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        if slide.isTemplate {
                            Image(systemName: "bookmark.fill")
                                .imageScale(.small)
                                .foregroundStyle(.tint)
                                .accessibilityLabel("Template slide")
                        }
                        if slide.isHidden {
                            Image(systemName: "eye.slash.fill")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Hidden from presentation")
                        }
                    }
                    Text("\(slide.elements.count) element\(slide.elements.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .opacity(slide.isHidden ? 0.45 : 1)
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
            Button {
                duplicate(slide, toChapterID: chapter.id)
            } label: {
                Label("Duplicate Slide", systemImage: "plus.square.on.square")
            }
            Button {
                setTemplate(!slide.isTemplate, slideID: slide.id)
            } label: {
                Label(
                    slide.isTemplate ? "Unmark as Template" : "Mark as Template",
                    systemImage: slide.isTemplate ? "bookmark.slash" : "bookmark"
                )
            }
            Button {
                setHidden(!slide.isHidden, slideID: slide.id)
            } label: {
                Label(
                    slide.isHidden ? "Show in Presentation" : "Hide from Presentation",
                    systemImage: slide.isHidden ? "eye" : "eye.slash"
                )
            }
            Divider()
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

    /// Deep-copies the slide with fresh element UUIDs but shares the underlying
    /// `AssetReference` so the package's image/video isn't re-imported.
    private func duplicate(_ source: Slide, toChapterID chapterID: UUID) {
        guard let idx = book.chapters.firstIndex(where: { $0.id == chapterID }) else { return }
        var copy = source
        copy.id = UUID()
        copy.isTemplate = false
        copy.elements = source.elements.map { element in
            var clone = element
            clone.id = UUID()
            return clone
        }
        book.chapters[idx].slides.append(copy)
        currentSlideID = copy.id
    }

    private func setTemplate(_ flag: Bool, slideID: UUID) {
        for chapterIdx in book.chapters.indices {
            if let slideIdx = book.chapters[chapterIdx].slides.firstIndex(where: { $0.id == slideID }) {
                book.chapters[chapterIdx].slides[slideIdx].isTemplate = flag
                return
            }
        }
    }

    private func setHidden(_ flag: Bool, slideID: UUID) {
        for chapterIdx in book.chapters.indices {
            if let slideIdx = book.chapters[chapterIdx].slides.firstIndex(where: { $0.id == slideID }) {
                book.chapters[chapterIdx].slides[slideIdx].isHidden = flag
                return
            }
        }
    }

    /// Reroute `currentSlideID` before removing so inspector/canvas don't briefly bind to a vanished slide.
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

    private func moveChapters(from source: IndexSet, to destination: Int) {
        book.chapters.move(fromOffsets: source, toOffset: destination)
    }

    private func moveSlides(in chapterID: UUID, from source: IndexSet, to destination: Int) {
        guard let idx = book.chapters.firstIndex(where: { $0.id == chapterID }) else { return }
        book.chapters[idx].slides.move(fromOffsets: source, toOffset: destination)
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
