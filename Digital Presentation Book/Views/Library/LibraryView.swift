import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(BookStore.self) private var store

    @State private var presentingBook: Book?
    @State private var editingBook: Book?
    @State private var showingImporter = false
    @State private var exportingBook: Book?
    @State private var deletingBook: Book?
    @State private var renamingBook: Book?
    @State private var renameDraft: String = ""

    @State private var showingTemplatePicker = false
    @State private var showingEditPicker = false
    @State private var showingAbout = false

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    createSection
                    if !store.books.isEmpty {
                        librarySection
                    } else {
                        emptyLibraryHint
                    }
                }
                .padding(20)
            }
            .background(.background.secondary)
            .navigationTitle("Presentations")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 8) {
                        BrandIcon()
                            .frame(width: 28, height: 28)
                        Text("Digital Presentation Book")
                            .font(.headline)
                    }
                }
                toolbarContent
            }
            .fullScreenCoverIfAvailable(item: $presentingBook) { book in
                PlayerView(book: book, package: store.package(for: book))
            }
            .fullScreenCoverIfAvailable(item: $editingBook) { book in
                BookEditorView(book: book, package: store.package(for: book), store: store)
            }
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerSheet { template, title in
                    createBook(from: template, title: title)
                }
            }
            .sheet(isPresented: $showingEditPicker) {
                EditBookPickerSheet(books: store.books) { book in
                    editingBook = book
                }
            }
            .sheet(isPresented: $showingAbout) {
                AboutSheet()
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: importContentTypes,
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .fileExporter(
                isPresented: Binding(
                    get: { exportingBook != nil },
                    set: { if !$0 { exportingBook = nil } }
                ),
                document: exportingBook.map {
                    ExportableBookDocument(packageDirectory: store.packageURL(for: $0.id))
                },
                // `.data` has no preferred extension, so the literal `.dpb`
                // in `defaultFilename` survives. The runtime-only
                // `.dpbPresentation` UTI made the system fall back to its
                // conforming type (`.zip`) and renamed the export `.zip`
                // because the custom UTI isn't declared in Info.plist.
                contentType: .data,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    store.lastError = error.localizedDescription
                }
                exportingBook = nil
            }
            .alert(
                "Delete this presentation?",
                isPresented: Binding(
                    get: { deletingBook != nil },
                    set: { if !$0 { deletingBook = nil } }
                ),
                presenting: deletingBook
            ) { book in
                Button("Delete", role: .destructive) {
                    try? store.delete(book)
                    deletingBook = nil
                }
                Button("Cancel", role: .cancel) { deletingBook = nil }
            } message: { book in
                Text("\"\(book.title)\" will be removed from this device. This can't be undone.")
            }
            .alert(
                "Rename Presentation",
                isPresented: Binding(
                    get: { renamingBook != nil },
                    set: { if !$0 { renamingBook = nil } }
                ),
                presenting: renamingBook
            ) { book in
                TextField("Title", text: $renameDraft)
                Button("Cancel", role: .cancel) { renamingBook = nil }
                Button("Save") {
                    let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    var updated = book
                    updated.title = trimmed.isEmpty ? "Untitled" : trimmed
                    do {
                        try store.save(updated)
                    } catch {
                        store.lastError = error.localizedDescription
                    }
                    renamingBook = nil
                }
            } message: { book in
                Text("Enter a new title for \"\(book.title)\".")
            }
            .onAppear { store.refresh() }
        }
    }

    private var createSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Create", systemImage: "sparkles")
            LazyVGrid(columns: columns, spacing: 20) {
                CreateBookCard(
                    title: "New Book",
                    subtitle: "Start with a blank slide and build from there.",
                    systemImage: "plus.rectangle.on.rectangle",
                    tint: .blue,
                    aspectRatio: 16.0 / 9.0
                ) {
                    createBook(from: .blank, title: nil)
                }

                CreateBookCard(
                    title: "From Template",
                    subtitle: "Pick a proven structure for sales calls or follow-ups.",
                    systemImage: "rectangle.stack.fill",
                    tint: .indigo,
                    aspectRatio: 16.0 / 9.0
                ) {
                    showingTemplatePicker = true
                }

                CreateBookCard(
                    title: "Edit a Book",
                    subtitle: editBookSubtitle,
                    systemImage: "pencil.and.outline",
                    tint: .orange,
                    aspectRatio: 16.0 / 9.0
                ) {
                    routeToEdit()
                }
            }
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Your Presentations", systemImage: "books.vertical.fill")
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(store.books) { book in
                    BookCard(
                        book: book,
                        package: store.package(for: book),
                        onOpen:   { presentingBook = book },
                        onEdit:   { editingBook = book },
                        onExport: { exportingBook = book },
                        onDelete: { deletingBook = book },
                        onRename: {
                            renameDraft = book.title
                            renamingBook = book
                        },
                        onToggleLock: { toggleLock(book) }
                    )
                }
            }
        }
    }

    private var emptyLibraryHint: some View {
        VStack(spacing: 12) {
            BrandIcon()
                .frame(width: 88, height: 88)
                .opacity(0.6)
            Text("No presentations yet")
                .font(.headline)
            Text("Tap a Create tile above, or import a .dpb file shared by a teammate.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.bold())
            .foregroundStyle(.primary)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showingImporter = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .disabled(!DPBArchive.isAvailable)

            Button {
                showingAbout = true
            } label: {
                Label("About", systemImage: "info.circle")
            }
        }
    }

    /// Build the import filter at runtime: `.dpbPresentation` is declared via
    /// `UTType(exportedAs:)` without an Info.plist entry, so the system can't
    /// match `.dpb` files to it. Synthesizing a UTI from the filename extension
    /// gives the picker something concrete to filter on, with `.zip` as a
    /// fallback for files that *do* carry the system zip UTI.
    private var importContentTypes: [UTType] {
        var types: [UTType] = [.dpbPresentation, .zip]
        if let dpb = UTType(filenameExtension: "dpb") {
            types.insert(dpb, at: 0)
        }
        return types
    }

    private var exportFilename: String {
        let base: String = {
            guard let book = exportingBook, !book.title.isEmpty else { return "Presentation" }
            return book.title
        }()
        return "\(base).dpb"
    }

    private var editBookSubtitle: String {
        switch store.books.count {
        case 0:  return "Create a book first, then come back to edit."
        case 1:  return "Open your presentation in the editor."
        default: return "Choose which of your \(store.books.count) presentations to edit."
        }
    }

    private func createBook(from template: BookTemplate, title: String?) {
        do {
            let book = try store.createBook(from: template, title: title)
            editingBook = book
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func routeToEdit() {
        switch store.books.count {
        case 0:
            // Library empty, fall through to New so the tile still works.
            createBook(from: .blank, title: nil)
        case 1:
            if let only = store.books.first { editingBook = only }
        default:
            showingEditPicker = true
        }
    }

    private func toggleLock(_ book: Book) {
        var updated = book
        updated.isLocked.toggle()
        do {
            try store.save(updated)
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsRelease = url.startAccessingSecurityScopedResource()
            defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }
            do {
                _ = try store.importPresentation(from: url)
            } catch {
                store.lastError = error.localizedDescription
            }
        case .failure(let error):
            store.lastError = error.localizedDescription
        }
    }
}

extension UTType {
    /// Declared as a subtype of `.zip` so system file pickers treat it as a
    /// single file rather than a folder.
    static let dpbPresentation: UTType = UTType(
        exportedAs: "com.starholder.digital-presentation-book.dpb",
        conformingTo: .zip
    )
}

/// Lazily zips a book's package directory when the system asks for its
/// bytes. Holds only a URL so SwiftUI can invoke it nonisolated.
private struct ExportableBookDocument: FileDocument {
    // `.data` matches the `contentType:` we pass to `fileExporter` so the
    // user-supplied `.dpb` extension survives.
    static var readableContentTypes: [UTType] { [.data] }
    static var writableContentTypes: [UTType] { [.data] }

    let packageDirectory: URL

    init(packageDirectory: URL) {
        self.packageDirectory = packageDirectory
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.featureUnsupported)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("export-\(UUID().uuidString).dpb")
        try DPBArchive.archive(packageDirectory: packageDirectory, to: tmp)
        let data = try Data(contentsOf: tmp)
        try? FileManager.default.removeItem(at: tmp)
        return FileWrapper(regularFileWithContents: data)
    }
}

private extension View {
    /// `fullScreenCover` is iOS-only; on macOS we fall back to a regular
    /// sheet so the same call site works on both platforms.
    @ViewBuilder
    func fullScreenCoverIfAvailable<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        self.fullScreenCover(item: item, content: content)
        #else
        self.sheet(item: item, content: content)
        #endif
    }
}
