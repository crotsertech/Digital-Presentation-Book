//
//  BookEditorView.swift
//  Digital Presentation Book
//
//  Top-level editor surface. Loads a working copy of the book so the user
//  can experiment freely; Save commits the copy through BookStore, Cancel
//  discards changes.
//
//  Layout: top control bar (always visible) — slide list (left) — canvas
//  (center) — inspector (right, when an element is selected). The control
//  bar is hand-rendered rather than relying on NavigationSplitView's
//  toolbar so it stays visible inside the fullScreenCover the Library
//  presents this view in.
//

import SwiftUI
import UniformTypeIdentifiers

struct BookEditorView: View {
    @State private var workingBook: Book
    @State private var currentSlideID: UUID?
    @State private var selectedElementID: UUID?
    @State private var hasUnsavedChanges: Bool = false
    @State private var discardConfirmation: Bool = false

    @State private var pendingAssetImport: PendingAssetImport?
    @State private var showingWidgetPicker: Bool = false

    let originalBook: Book
    let package: DPBPackage
    let store: BookStore

    @Environment(\.dismiss) private var dismiss

    init(book: Book, package: DPBPackage, store: BookStore) {
        self.originalBook = book
        self.package = package
        self.store = store
        _workingBook = State(initialValue: book)
        _currentSlideID = State(initialValue: book.allSlides.first?.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            topControlBar
            Divider()
            mainArea
        }
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.delete) {
            deleteSelectedElement()
            return .handled
        }
        .onKeyPress(.escape) {
            selectedElementID = nil
            return .handled
        }
        .onChange(of: workingBook) {
            hasUnsavedChanges = workingBook != originalBook
        }
        .confirmationDialog(
            "Discard unsaved changes?",
            isPresented: $discardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard changes", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) { }
        }
        .fileImporter(
            isPresented: Binding(
                get: { pendingAssetImport != nil },
                set: { if !$0 { pendingAssetImport = nil } }
            ),
            allowedContentTypes: pendingAssetImport?.allowedContentTypes ?? [.data],
            allowsMultipleSelection: false
        ) { result in
            handleAssetImport(result)
        }
        .sheet(isPresented: $showingWidgetPicker) {
            WidgetPickerSheet { widgetType in
                insertWidget(widgetType)
            }
        }
    }

    // MARK: - Top control bar

    private var topControlBar: some View {
        HStack(spacing: 12) {
            Button(role: .cancel) {
                if hasUnsavedChanges {
                    discardConfirmation = true
                } else {
                    dismiss()
                }
            } label: {
                Label("Cancel", systemImage: "xmark")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)

            Divider().frame(height: 24)

            addElementMenu

            Divider().frame(height: 24)

            VStack(alignment: .leading, spacing: 0) {
                Text(workingBook.title)
                    .font(.headline)
                    .lineLimit(1)
                if hasUnsavedChanges {
                    Text("Unsaved changes")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.orange)
                } else {
                    Text(slideCountLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(role: .destructive) {
                deleteSelectedElement()
            } label: {
                Label("Delete element", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .disabled(selectedElementID == nil)

            Button {
                save()
            } label: {
                Label("Save", systemImage: "checkmark")
                    .labelStyle(.titleAndIcon)
                    .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasUnsavedChanges)
            .keyboardShortcut("s", modifiers: [.command])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var addElementMenu: some View {
        Menu {
            Button {
                insertText()
            } label: {
                Label("Text", systemImage: "textformat")
            }

            Section("Shapes") {
                Button {
                    insertShape(.rectangle)
                } label: {
                    Label("Rectangle", systemImage: "rectangle")
                }
                Button {
                    insertShape(.roundedRectangle)
                } label: {
                    Label("Rounded Rectangle", systemImage: "rectangle.roundedtop")
                }
                Button {
                    insertShape(.ellipse)
                } label: {
                    Label("Ellipse", systemImage: "circle")
                }
            }

            Section("Media") {
                Button {
                    pendingAssetImport = .image
                } label: {
                    Label("Image…", systemImage: "photo")
                }
                Button {
                    pendingAssetImport = .video
                } label: {
                    Label("Video…", systemImage: "play.rectangle")
                }
            }

            Section("Widgets") {
                Button {
                    showingWidgetPicker = true
                } label: {
                    Label("Choose Widget…", systemImage: "puzzlepiece.extension")
                }
            }
        } label: {
            Label("Add", systemImage: "plus")
                .labelStyle(.titleAndIcon)
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.borderedProminent)
        .disabled(currentSlideID == nil)
    }

    // MARK: - Main area

    private var mainArea: some View {
        HStack(spacing: 0) {
            EditorSlideList(book: workingBook, currentSlideID: $currentSlideID)
                .frame(width: 260)
                .background(.background.secondary)

            Divider()

            canvasPane

            if let binding = selectedElementBinding {
                Divider()
                EditorInspector(
                    element: binding,
                    book: workingBook,
                    onDelete: deleteSelectedElement
                )
                .frame(width: 340)
                .background(.background)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: selectedElementID)
    }

    private var canvasPane: some View {
        Group {
            if let binding = currentSlideBinding {
                EditorCanvas(
                    slide: binding,
                    book: workingBook,
                    package: package,
                    selectedElementID: $selectedElementID
                )
                .padding(24)
            } else {
                ContentUnavailableView(
                    "No slides yet",
                    systemImage: "rectangle.dashed",
                    description: Text("Add a slide to begin editing.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - State helpers

    private var slideCountLabel: String {
        let total = workingBook.allSlides.count
        return "\(total) slide\(total == 1 ? "" : "s")"
    }

    private var currentSlideBinding: Binding<Slide>? {
        guard let id = currentSlideID else { return nil }
        for chapterIdx in workingBook.chapters.indices {
            if let slideIdx = workingBook.chapters[chapterIdx].slides.firstIndex(where: { $0.id == id }) {
                return Binding(
                    get: { workingBook.chapters[chapterIdx].slides[slideIdx] },
                    set: { workingBook.chapters[chapterIdx].slides[slideIdx] = $0 }
                )
            }
        }
        return nil
    }

    private var selectedElementBinding: Binding<SlideElement>? {
        guard let elementID = selectedElementID else { return nil }
        for chapterIdx in workingBook.chapters.indices {
            for slideIdx in workingBook.chapters[chapterIdx].slides.indices {
                if let elementIdx = workingBook.chapters[chapterIdx].slides[slideIdx].elements.firstIndex(where: { $0.id == elementID }) {
                    return Binding(
                        get: { workingBook.chapters[chapterIdx].slides[slideIdx].elements[elementIdx] },
                        set: { workingBook.chapters[chapterIdx].slides[slideIdx].elements[elementIdx] = $0 }
                    )
                }
            }
        }
        return nil
    }

    private func deleteSelectedElement() {
        guard let selectionID = selectedElementID else { return }
        for chapterIdx in workingBook.chapters.indices {
            for slideIdx in workingBook.chapters[chapterIdx].slides.indices {
                workingBook.chapters[chapterIdx].slides[slideIdx].elements.removeAll {
                    $0.id == selectionID
                }
            }
        }
        selectedElementID = nil
    }

    private func save() {
        do {
            try store.save(workingBook)
            dismiss()
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    // MARK: - Insertion

    private func insertText() {
        let element = SlideElement(
            frame: NormalizedRect(x: 0.20, y: 0.42, width: 0.60, height: 0.16),
            content: .text(TextElementData(
                string: "Tap to edit",
                fontSize: 48,
                fontWeight: .bold,
                color: workingBook.theme.defaultTextColor,
                alignment: .center,
                lineSpacing: 0,
                fontFamily: nil
            ))
        )
        insert(element)
    }

    private func insertShape(_ kind: ShapeElementData.ShapeKind) {
        let element = SlideElement(
            frame: NormalizedRect(x: 0.30, y: 0.30, width: 0.40, height: 0.40),
            content: .shape(ShapeElementData(
                kind: kind,
                fill: workingBook.theme.primaryColor,
                stroke: nil,
                strokeWidth: 0,
                cornerRadius: kind == .roundedRectangle ? 16 : 0
            ))
        )
        insert(element)
    }

    private func insertImage(from url: URL) {
        do {
            try package.ensureDirectoryStructure()
            let asset = try package.importAsset(from: url, mimeType: mimeType(for: url))
            let element = SlideElement(
                frame: NormalizedRect(x: 0.20, y: 0.20, width: 0.60, height: 0.60),
                content: .image(ImageElementData(
                    asset: asset,
                    fill: .aspectFit,
                    cornerRadius: 0
                ))
            )
            insert(element)
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func insertVideo(from url: URL) {
        do {
            try package.ensureDirectoryStructure()
            let asset = try package.importAsset(from: url, mimeType: mimeType(for: url))
            let element = SlideElement(
                frame: NormalizedRect(x: 0.15, y: 0.20, width: 0.70, height: 0.55),
                content: .video(VideoElementData(
                    asset: asset,
                    autoplay: false,
                    loops: false,
                    showsControls: true,
                    muted: false
                ))
            )
            insert(element)
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func insertWidget(_ widgetType: SlideWidget.Type) {
        let element = SlideElement(
            frame: NormalizedRect(x: 0.10, y: 0.18, width: 0.80, height: 0.66),
            content: .widget(WidgetElementData(
                widgetID: widgetType.widgetID,
                parameters: widgetType.defaultParameters
            ))
        )
        insert(element)
    }

    /// Append `element` to the current slide and auto-select it so the
    /// inspector slides in for immediate tuning.
    private func insert(_ element: SlideElement) {
        guard let id = currentSlideID else { return }
        for chapterIdx in workingBook.chapters.indices {
            if let slideIdx = workingBook.chapters[chapterIdx].slides.firstIndex(where: { $0.id == id }) {
                workingBook.chapters[chapterIdx].slides[slideIdx].elements.append(element)
                selectedElementID = element.id
                return
            }
        }
    }

    // MARK: - Asset import

    private func handleAssetImport(_ result: Result<[URL], Error>) {
        let kind = pendingAssetImport
        pendingAssetImport = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }

            switch kind {
            case .image: insertImage(from: url)
            case .video: insertVideo(from: url)
            case .none:  break
            }

        case .failure(let error):
            store.lastError = error.localizedDescription
        }
    }

    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png":           return "image/png"
        case "jpg", "jpeg":   return "image/jpeg"
        case "heic", "heif":  return "image/heic"
        case "gif":           return "image/gif"
        case "webp":          return "image/webp"
        case "mp4", "m4v":    return "video/mp4"
        case "mov":           return "video/quicktime"
        case "m4a":           return "audio/mp4"
        default:              return "application/octet-stream"
        }
    }
}

// MARK: - Pending import enum

private enum PendingAssetImport: Identifiable, Hashable {
    case image
    case video

    var id: Self { self }

    var allowedContentTypes: [UTType] {
        switch self {
        case .image: return [.image, .png, .jpeg, .heic, .gif]
        case .video: return [.movie, .video, .quickTimeMovie, .mpeg4Movie]
        }
    }
}
