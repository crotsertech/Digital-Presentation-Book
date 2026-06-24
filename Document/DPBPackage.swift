//
//  DPBPackage.swift
//  Digital Presentation Book
//
//  Read/write the on-disk representation of a Book.
//
//  Internal storage layout (a directory inside the app's Documents folder):
//
//      Library/<book-uuid>.dpb/
//          manifest.json          // encoded Book
//          assets/                // binary blobs referenced by manifest
//          thumbnails/            // optional cached slide previews
//
//  For import/export we zip the directory into a single .dpb file. Zipping
//  is handled by `DPBArchive` (see DPBArchive.swift) so this type stays
//  focused on the on-disk layout.
//

import Foundation

enum DPBPackageError: LocalizedError {
    case manifestMissing
    case manifestUnreadable(underlying: Error)
    case assetMissing(name: String)
    case writeFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .manifestMissing:
            return "The presentation is missing its manifest.json."
        case .manifestUnreadable(let e):
            return "The manifest could not be read: \(e.localizedDescription)"
        case .assetMissing(let n):
            return "Asset \(n) is missing from the package."
        case .writeFailed(let e):
            return "Couldn't write the package: \(e.localizedDescription)"
        }
    }
}

/// Read/write a `.dpb` package directory. The same shape is used both for
/// the library's on-disk storage and for the contents of an exported zip.
struct DPBPackage {
    static let manifestFilename = "manifest.json"
    static let assetsDirectory = "assets"
    static let thumbnailsDirectory = "thumbnails"

    /// Filesystem location of the package directory.
    let url: URL

    init(url: URL) {
        self.url = url
    }

    /// Directory at `url` containing `manifest.json`, `assets/`, etc.
    var manifestURL: URL { url.appendingPathComponent(Self.manifestFilename) }
    var assetsURL: URL { url.appendingPathComponent(Self.assetsDirectory) }
    var thumbnailsURL: URL { url.appendingPathComponent(Self.thumbnailsDirectory) }

    // MARK: - Manifest

    /// Decode the manifest from disk.
    func readBook() throws -> Book {
        let fm = FileManager.default
        guard fm.fileExists(atPath: manifestURL.path) else {
            throw DPBPackageError.manifestMissing
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Book.self, from: data)
        } catch let error as DPBPackageError {
            throw error
        } catch {
            throw DPBPackageError.manifestUnreadable(underlying: error)
        }
    }

    /// Write the manifest to disk and ensure all required subdirectories
    /// exist. Asset files themselves are managed separately via
    /// `importAsset(...)`.
    func writeBook(_ book: Book) throws {
        do {
            try ensureDirectoryStructure()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(book)
            try data.write(to: manifestURL, options: .atomic)
        } catch {
            throw DPBPackageError.writeFailed(underlying: error)
        }
    }

    /// Create the package directory and its expected subdirectories if they
    /// don't already exist.
    func ensureDirectoryStructure() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        try fm.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
    }

    // MARK: - Assets

    /// Copy a binary asset into the package. Returns an `AssetReference`
    /// the caller can attach to a slide element.
    @discardableResult
    func importAsset(from source: URL, mimeType: String) throws -> AssetReference {
        try ensureDirectoryStructure()
        let id = UUID()
        let ext = source.pathExtension.lowercased()
        let dest = assetsURL.appendingPathComponent("\(id.uuidString).\(ext)")
        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.copyItem(at: source, to: dest)
        let size = (try? fm.attributesOfItem(atPath: dest.path)[.size] as? Int) ?? 0
        return AssetReference(
            id: id,
            originalName: source.lastPathComponent,
            fileExtension: ext,
            mimeType: mimeType,
            byteSize: size
        )
    }

    /// URL inside the package for a given asset reference. Doesn't verify
    /// the file actually exists — call `assetExists` for that.
    func url(for asset: AssetReference) -> URL {
        assetsURL.appendingPathComponent(asset.storedFilename)
    }

    func assetExists(_ asset: AssetReference) -> Bool {
        FileManager.default.fileExists(atPath: url(for: asset).path)
    }
}
