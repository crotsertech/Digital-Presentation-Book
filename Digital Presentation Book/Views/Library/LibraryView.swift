//
//  LibraryView.swift
//  Digital Presentation Book
//
//  Home screen showing the salesperson's installed presentations. The
//  page has two grids: a "Create" row with dedicated New / From Template
//  / Edit Book tiles, and the existing-presentation grid below.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(BookStore.self) private var store

    @State private var presentingBook: Book?
    @State private var editingBook: Book?
    @State private var showingImporter = false
    @State private var exportingBook: Book?
    @State private var deletingBook: Book?

    @State private var showingTemplatePicker = false
    @State private var showingEditPicker = false

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
            .toolbar { toolbarContent }
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
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.dpbPresentation, .zip],
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
                contentType: .dpbPresentation,
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
            .onAppear { store.refresh() }
        }
    }

    // MARK: - Sections

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
                        onOpen:   { presentingBook = book },
                        onEdit:   { editingBook = book },
                        onExport: { exportingBook = book },
                        onDelete: { deletingBook = book }
                    )
                }
            }
        }
    }

    private var emptyLibraryHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "books.vertical")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
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
        }
    }

    // MARK: - Actions

    private var exportFilename: String {
        guard let book = exportingBook else { return "Presentation" }
        return book.title.isEmpty ? "Presentation" : book.title
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
            // Jump straight into the editor so the rep can customize.
            editingBook = book
        } catch {
            store.lastError = error.localizedDescription
        }
    }

    private func routeToEdit() {
        switch store.books.count {
        case 0:
            // Falling through to the New flow makes the tile useful even
            // before the library has anything in it.
            createBook(from: .blank, title: nil)
        case 1:
            if let only = store.books.first { editingBook = only }
        default:
            showingEditPicker = true
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

// MARK: - .dpb file type

extension UTType {
    /// The custom Digital Presentation Book document type. We declare it as
    /// a subtype of `.zip` so the system file pickers treat it as a single
    /// file rather than a folder.
    static let dpbPresentation: UTType = UTType(
        exportedAs: "com.starholder.digital-presentation-book.dpb",
        conformingTo: .zip
    )
}

// MARK: - Exporter shim

/// A `FileDocument` that lazily zips a book's package directory into a
/// transferable .dpb file when the system asks for its bytes. Holds only a
/// URL so it can run nonisolated when SwiftUI invokes it.
private struct ExportableBookDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.dpbPresentation] }
    static var writableContentTypes: [UTType] { [.dpbPresentation] }

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

// MARK: - Cross-platform fullScreenCover

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
