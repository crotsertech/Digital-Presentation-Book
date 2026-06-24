//
//  LibraryView.swift
//  Digital Presentation Book
//
//  Home screen showing the salesperson's installed presentations and
//  letting them import / export / delete books.
//

import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(BookStore.self) private var store

    @State private var presentingBook: Book?
    @State private var showingImporter = false
    @State private var exportingBook: Book?
    @State private var deletingBook: Book?

    private let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 360), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if store.books.isEmpty {
                    emptyState
                        .frame(minHeight: 480)
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(store.books) { book in
                            BookCard(
                                book: book,
                                onOpen:   { presentingBook = book },
                                onExport: { exportingBook = book },
                                onDelete: { deletingBook = book }
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .background(.background.secondary)
            .navigationTitle("Presentations")
            .toolbar { toolbarContent }
            .fullScreenCoverIfAvailable(item: $presentingBook) { book in
                PlayerView(book: book, package: store.package(for: book))
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
                document: exportingBook.map { ExportableBookDocument(book: $0, store: store) },
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

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No presentations yet", systemImage: "books.vertical")
        } description: {
            Text("Create a new book or import a .dpb file shared by a teammate.")
        } actions: {
            HStack {
                Button {
                    createSampleBook()
                } label: {
                    Label("Add Sample Book", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    showingImporter = true
                } label: {
                    Label("Import…", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .disabled(!DPBArchive.isAvailable)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                createSampleBook()
            } label: {
                Label("Add Sample", systemImage: "sparkles")
            }

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

    private func createSampleBook() {
        do {
            try store.save(SampleBook.make())
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
/// transferable .dpb file when the system asks for its bytes.
private struct ExportableBookDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.dpbPresentation] }
    static var writableContentTypes: [UTType] { [.dpbPresentation] }

    let book: Book
    let store: BookStore

    init(book: Book, store: BookStore) {
        self.book = book
        self.store = store
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.featureUnsupported)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("export-\(UUID().uuidString).dpb")
        try store.exportPresentation(book, to: tmp)
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
