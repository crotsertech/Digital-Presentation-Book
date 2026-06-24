//
//  BookStore.swift
//  Digital Presentation Book
//
//  Owns the on-disk library of presentations and exposes an observable
//  list to SwiftUI. Each book lives in its own `.dpb` package directory
//  inside `Documents/Library/`.
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class BookStore {
    /// Books currently known to the store, sorted newest-updated first.
    private(set) var books: [Book] = []

    /// Surfaced to the UI for transient error toasts.
    var lastError: String?

    private let libraryDirectory: URL

    init(libraryDirectory: URL? = nil) {
        if let libraryDirectory {
            self.libraryDirectory = libraryDirectory
        } else {
            let docs = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            self.libraryDirectory = docs.appendingPathComponent("Library", isDirectory: true)
        }
        try? FileManager.default.createDirectory(
            at: self.libraryDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Discovery

    /// Reload the in-memory list from disk.
    func refresh() {
        let fm = FileManager.default
        guard
            let entries = try? fm.contentsOfDirectory(
                at: libraryDirectory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        else {
            books = []
            return
        }

        var found: [Book] = []
        for entry in entries where entry.pathExtension.lowercased() == "dpb" {
            let pkg = DPBPackage(url: entry)
            if let book = try? pkg.readBook() {
                found.append(book)
            }
        }
        books = found.sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - CRUD

    /// Filesystem URL where a book of the given id lives in the library.
    func packageURL(for bookID: UUID) -> URL {
        libraryDirectory.appendingPathComponent("\(bookID.uuidString).dpb", isDirectory: true)
    }

    func package(for book: Book) -> DPBPackage {
        DPBPackage(url: packageURL(for: book.id))
    }

    /// Persist a new or modified book.
    func save(_ book: Book) throws {
        var updated = book
        updated.updatedAt = .now
        updated.revision += 1
        let pkg = DPBPackage(url: packageURL(for: updated.id))
        try pkg.writeBook(updated)
        if let idx = books.firstIndex(where: { $0.id == updated.id }) {
            books[idx] = updated
        } else {
            books.insert(updated, at: 0)
        }
    }

    func delete(_ book: Book) throws {
        let url = packageURL(for: book.id)
        try FileManager.default.removeItem(at: url)
        books.removeAll { $0.id == book.id }
    }

    // MARK: - Import / Export

    /// Import a `.dpb` archive from outside the library. The file is
    /// extracted into the library directory and the manifest is read.
    func importPresentation(from archive: URL) throws -> Book {
        let tempDirectory = libraryDirectory.appendingPathComponent(
            "_import-\(UUID().uuidString)",
            isDirectory: true
        )
        try DPBArchive.extract(archiveFile: archive, to: tempDirectory)

        let pkg = DPBPackage(url: tempDirectory)
        let imported = try pkg.readBook()

        // Move to its canonical location (overwrite if present).
        let dest = packageURL(for: imported.id)
        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.moveItem(at: tempDirectory, to: dest)

        if let idx = books.firstIndex(where: { $0.id == imported.id }) {
            books[idx] = imported
        } else {
            books.insert(imported, at: 0)
        }
        books.sort { $0.updatedAt > $1.updatedAt }
        return imported
    }

    /// Zip a book's package into a single `.dpb` file at `destination`.
    func exportPresentation(_ book: Book, to destination: URL) throws {
        try DPBArchive.archive(
            packageDirectory: packageURL(for: book.id),
            to: destination
        )
    }
}
