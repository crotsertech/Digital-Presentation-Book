import SwiftUI
import UniformTypeIdentifiers

// The control bar is hand-rendered (not NavigationSplitView's toolbar) so it
// stays visible inside the fullScreenCover that the Library presents this
// view in. Split-view toolbars don't survive that container.

struct BookEditorView: View {
    @State private var workingBook: Book
    @State private var currentSlideID: UUID?
    @State private var selectedElementID: UUID?
    @State private var hasUnsavedChanges: Bool = false
    @State private var discardConfirmation: Bool = false

    /// Kept distinct from `showingAssetImporter` so the importer's reset
    /// doesn't clobber it before the completion runs.
    @State private var pendingAssetImport: PendingAssetImport?
    @State private var showingAssetImporter: Bool = false
    @State private var showingWidgetPicker: Bool = false
    @State private var showingBackgroundPicker: Bool = false
    @State private var showingImageAssetPicker: Bool = false
    @State private var showingVideoAssetPicker: Bool = false
    @State private var showingBackgroundImageAssetPicker: Bool = false

    /// Snapshots of `workingBook` *before* each user mutation; the most
    /// recent is at the end of the array.
    @State private var undoStack: [Book] = []
    @State private var redoStack: [Book] = []
    /// Set by `undo`/`redo` so the resulting `onChange(workingBook)` doesn't
    /// record the swap back as another history entry.
    @State private var isApplyingHistory: Bool = false
    /// Each entry is a full Book snapshot, so cap depth to keep memory
    /// bounded over long editing sessions.
    private let historyLimit: Int = 100

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
        .onChange(of: workingBook) { oldValue, newValue in
            hasUnsavedChanges = newValue != originalBook
            if isApplyingHistory {
                isApplyingHistory = false
                return
            }
            undoStack.append(oldValue)
            if undoStack.count > historyLimit {
                undoStack.removeFirst(undoStack.count - historyLimit)
            }
            redoStack.removeAll()
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
            isPresented: $showingAssetImporter,
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
        .sheet(isPresented: $showingBackgroundPicker) {
            if let slide = currentSlideBinding?.wrappedValue {
                BackgroundPickerSheet(
                    book: workingBook,
                    currentBackground: slide.background,
                    onSelectPreset: { preset in
                        applyBackgroundPreset(preset)
                    },
                    onUploadImage: {
                        presentAssetImporter(.backgroundImage)
                    },
                    onChooseExistingImage: {
                        showingBackgroundImageAssetPicker = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingImageAssetPicker) {
            BookAssetPicker(
                book: workingBook,
                package: package,
                kind: .image,
                onSelect: { asset in
                    insertImage(reusing: asset)
                },
                onUploadNew: {
                    presentAssetImporter(.image)
                }
            )
        }
        .sheet(isPresented: $showingVideoAssetPicker) {
            BookAssetPicker(
                book: workingBook,
                package: package,
                kind: .video,
                onSelect: { asset in
                    insertVideo(reusing: asset)
                },
                onUploadNew: {
                    presentAssetImporter(.video)
                }
            )
        }
        .sheet(isPresented: $showingBackgroundImageAssetPicker) {
            BookAssetPicker(
                book: workingBook,
                package: package,
                kind: .image,
                onSelect: { asset in
                    setBackground(.image(asset, fill: .aspectFill))
                },
                onUploadNew: {
                    presentAssetImporter(.backgroundImage)
                }
            )
        }
    }

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

            Button {
                undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .disabled(undoStack.isEmpty)
            .keyboardShortcut("z", modifiers: [.command])
            .help("Undo")

            Button {
                redo()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .disabled(redoStack.isEmpty)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .help("Redo")

            Divider().frame(height: 24)

            addElementMenu

            Button {
                showingBackgroundPicker = true
            } label: {
                Label("Background", systemImage: "paintpalette")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
            .disabled(currentSlideID == nil)

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
                    showingImageAssetPicker = true
                } label: {
                    Label("Image…", systemImage: "photo")
                }
                Button {
                    showingVideoAssetPicker = true
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

    private var mainArea: some View {
        HStack(spacing: 0) {
            EditorSlideList(book: $workingBook, currentSlideID: $currentSlideID)
                .frame(width: 260)
                .background(.background.secondary)

            Divider()

            canvasPane

            if let binding = selectedElementBinding {
                Divider()
                EditorInspector(
                    element: binding,
                    book: workingBook,
                    package: package,
                    onDelete: deleteSelectedElement,
                    onDuplicate: duplicateSelectedElement,
                    onBringForward: { moveSelectedElement(.forward) },
                    onSendBackward: { moveSelectedElement(.backward) },
                    onBringToFront: { moveSelectedElement(.toFront) },
                    onSendToBack: { moveSelectedElement(.toBack) },
                    onRequestImageReplaceUpload: {
                        presentAssetImporter(.replaceImage)
                    },
                    onRequestVideoReplaceUpload: {
                        presentAssetImporter(.replaceVideo)
                    }
                )
                .frame(width: 340)
                .background(.background)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else if let slideBinding = currentSlideBinding {
                Divider()
                SlideInspector(slide: slideBinding)
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

    private var slideCountLabel: String {
        let total = workingBook.allSlides.count
        return "\(total) slide\(total == 1 ? "" : "s")"
    }

    /// ID-keyed binding with a snapshot fallback so a deleted slide doesn't
    /// trigger an out-of-bounds read while SwiftUI tears the view down. The
    /// same trick is used for `selectedElementBinding`.
    private var currentSlideBinding: Binding<Slide>? {
        guard let id = currentSlideID else { return nil }
        guard let snapshot = findSlide(id: id) else { return nil }
        return Binding(
            get: { findSlide(id: id) ?? snapshot },
            set: { newValue in
                for chapterIdx in workingBook.chapters.indices {
                    if let slideIdx = workingBook.chapters[chapterIdx].slides.firstIndex(where: { $0.id == id }) {
                        workingBook.chapters[chapterIdx].slides[slideIdx] = newValue
                        return
                    }
                }
            }
        )
    }

    private func findSlide(id: UUID) -> Slide? {
        for chapter in workingBook.chapters {
            if let slide = chapter.slides.first(where: { $0.id == id }) {
                return slide
            }
        }
        return nil
    }

    /// Resolves the selected element by ID on each access. Capturing an
    /// array index would crash mid-delete because SwiftUI still calls the
    /// old binding's get during the inspector's dismissal animation. The
    /// snapshot fallback keeps that read safe.
    private var selectedElementBinding: Binding<SlideElement>? {
        guard let elementID = selectedElementID else { return nil }
        guard let snapshot = findElement(id: elementID) else { return nil }
        return Binding(
            get: { findElement(id: elementID) ?? snapshot },
            set: { newValue in
                for chapterIdx in workingBook.chapters.indices {
                    for slideIdx in workingBook.chapters[chapterIdx].slides.indices {
                        if let elementIdx = workingBook.chapters[chapterIdx].slides[slideIdx].elements.firstIndex(where: { $0.id == elementID }) {
                            workingBook.chapters[chapterIdx].slides[slideIdx].elements[elementIdx] = newValue
                            return
                        }
                    }
                }
            }
        )
    }

    private func findElement(id: UUID) -> SlideElement? {
        for chapter in workingBook.chapters {
            for slide in chapter.slides {
                if let element = slide.elements.first(where: { $0.id == id }) {
                    return element
                }
            }
        }
        return nil
    }

    private func deleteSelectedElement() {
        guard let selectionID = selectedElementID else { return }
        // Unmount the inspector before the element disappears from the
        // array, otherwise the binding briefly reads a removed index.
        selectedElementID = nil
        for chapterIdx in workingBook.chapters.indices {
            for slideIdx in workingBook.chapters[chapterIdx].slides.indices {
                workingBook.chapters[chapterIdx].slides[slideIdx].elements.removeAll {
                    $0.id == selectionID
                }
            }
        }
    }

    private enum ZMove {
        case forward, backward, toFront, toBack
    }

    /// `elements` renders bottom-to-top, so the last index is on top.
    private func moveSelectedElement(_ move: ZMove) {
        guard let elementID = selectedElementID else { return }
        for chapterIdx in workingBook.chapters.indices {
            for slideIdx in workingBook.chapters[chapterIdx].slides.indices {
                var elements = workingBook.chapters[chapterIdx].slides[slideIdx].elements
                guard let idx = elements.firstIndex(where: { $0.id == elementID }) else { continue }
                let element = elements.remove(at: idx)
                switch move {
                case .forward:
                    elements.insert(element, at: min(idx + 1, elements.count))
                case .backward:
                    elements.insert(element, at: max(idx - 1, 0))
                case .toFront:
                    elements.append(element)
                case .toBack:
                    elements.insert(element, at: 0)
                }
                workingBook.chapters[chapterIdx].slides[slideIdx].elements = elements
                return
            }
        }
    }

    /// The duplicate gets a fresh UUID but reuses every other field
    /// verbatim, including any `AssetReference`, so the image/video blob
    /// is not re-imported into the package.
    private func duplicateSelectedElement() {
        guard let elementID = selectedElementID else { return }
        for chapterIdx in workingBook.chapters.indices {
            for slideIdx in workingBook.chapters[chapterIdx].slides.indices {
                let elements = workingBook.chapters[chapterIdx].slides[slideIdx].elements
                guard let idx = elements.firstIndex(where: { $0.id == elementID }) else { continue }
                var copy = elements[idx]
                copy.id = UUID()
                copy.frame.x = min(max(copy.frame.x + 0.02, 0), 1 - copy.frame.width)
                copy.frame.y = min(max(copy.frame.y + 0.02, 0), 1 - copy.frame.height)
                workingBook.chapters[chapterIdx].slides[slideIdx].elements.insert(copy, at: idx + 1)
                selectedElementID = copy.id
                return
            }
        }
    }

    private func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(workingBook)
        isApplyingHistory = true
        workingBook = previous
        // Selection may point at an element/slide that doesn't exist in
        // the restored state. Close the inspector instead of crashing.
        if let id = selectedElementID, findElement(id: id) == nil {
            selectedElementID = nil
        }
        if let id = currentSlideID, findSlide(id: id) == nil {
            currentSlideID = workingBook.allSlides.first?.id
        }
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(workingBook)
        isApplyingHistory = true
        workingBook = next
        if let id = selectedElementID, findElement(id: id) == nil {
            selectedElementID = nil
        }
        if let id = currentSlideID, findSlide(id: id) == nil {
            currentSlideID = workingBook.allSlides.first?.id
        }
    }

    private func save() {
        do {
            try store.save(workingBook)
            dismiss()
        } catch {
            store.lastError = error.localizedDescription
        }
    }

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

    /// Reuses an existing package asset. No file copy, no re-import; the
    /// blob is shared with every other reference to it.
    private func insertImage(reusing asset: AssetReference) {
        let element = SlideElement(
            frame: NormalizedRect(x: 0.20, y: 0.20, width: 0.60, height: 0.60),
            content: .image(ImageElementData(
                asset: asset,
                fill: .aspectFit,
                cornerRadius: 0
            ))
        )
        insert(element)
    }

    private func insertVideo(reusing asset: AssetReference) {
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

    private func replaceSelectedImage(with asset: AssetReference) {
        mutateSelectedImage { $0.asset = asset }
    }

    private func replaceSelectedImage(uploadedFrom url: URL) {
        do {
            try package.ensureDirectoryStructure()
            let asset = try package.importAsset(from: url, mimeType: mimeType(for: url))
            mutateSelectedImage { $0.asset = asset }
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func replaceSelectedVideo(with asset: AssetReference) {
        mutateSelectedVideo { $0.asset = asset }
    }

    private func replaceSelectedVideo(uploadedFrom url: URL) {
        do {
            try package.ensureDirectoryStructure()
            let asset = try package.importAsset(from: url, mimeType: mimeType(for: url))
            mutateSelectedVideo { $0.asset = asset }
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func mutateSelectedImage(_ transform: (inout ImageElementData) -> Void) {
        guard let binding = selectedElementBinding else { return }
        guard case .image(var data) = binding.wrappedValue.content else { return }
        transform(&data)
        var updated = binding.wrappedValue
        updated.content = .image(data)
        binding.wrappedValue = updated
    }

    private func mutateSelectedVideo(_ transform: (inout VideoElementData) -> Void) {
        guard let binding = selectedElementBinding else { return }
        guard case .video(var data) = binding.wrappedValue.content else { return }
        transform(&data)
        var updated = binding.wrappedValue
        updated.content = .video(data)
        binding.wrappedValue = updated
    }

    private func applyBackgroundPreset(_ preset: BackgroundPreset) {
        setBackground(preset.makeBackground(book: workingBook))
    }

    private func setBackgroundImage(from url: URL) {
        do {
            try package.ensureDirectoryStructure()
            let asset = try package.importAsset(from: url, mimeType: mimeType(for: url))
            setBackground(.image(asset, fill: .aspectFill))
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func setBackground(_ background: SlideBackground) {
        guard let id = currentSlideID else { return }
        for chapterIdx in workingBook.chapters.indices {
            if let slideIdx = workingBook.chapters[chapterIdx].slides.firstIndex(where: { $0.id == id }) {
                workingBook.chapters[chapterIdx].slides[slideIdx].background = background
                return
            }
        }
    }

    /// Two-step state (set `kind`, then flip the presentation flag) keeps
    /// `kind` alive for the completion to read after the picker dismisses.
    private func presentAssetImporter(_ kind: PendingAssetImport) {
        pendingAssetImport = kind
        showingAssetImporter = true
    }

    private func handleAssetImport(_ result: Result<[URL], Error>) {
        let kind = pendingAssetImport
        pendingAssetImport = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }

            switch kind {
            case .image:           insertImage(from: url)
            case .video:           insertVideo(from: url)
            case .backgroundImage: setBackgroundImage(from: url)
            case .replaceImage:    replaceSelectedImage(uploadedFrom: url)
            case .replaceVideo:    replaceSelectedVideo(uploadedFrom: url)
            case .none:            store.lastError = "Internal: import kind lost before completion."
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

private enum PendingAssetImport: Identifiable, Hashable {
    case image
    case video
    case backgroundImage
    case replaceImage
    case replaceVideo

    var id: Self { self }

    var allowedContentTypes: [UTType] {
        switch self {
        case .image, .backgroundImage, .replaceImage:
            return [.image, .png, .jpeg, .heic, .gif]
        case .video, .replaceVideo:
            return [.movie, .video, .quickTimeMovie, .mpeg4Movie]
        }
    }
}
