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

/// On-disk shape of a `.dpb`:
///
///     Library/<book-uuid>.dpb/
///         manifest.json
///         assets/
///         thumbnails/
///
/// The same layout is used inside the exported zip. `DPBArchive` only
/// compresses it.
struct DPBPackage {
    static let manifestFilename = "manifest.json"
    static let assetsDirectory = "assets"
    static let thumbnailsDirectory = "thumbnails"

    let url: URL

    init(url: URL) {
        self.url = url
    }

    var manifestURL: URL { url.appendingPathComponent(Self.manifestFilename) }
    var assetsURL: URL { url.appendingPathComponent(Self.assetsDirectory) }
    var thumbnailsURL: URL { url.appendingPathComponent(Self.thumbnailsDirectory) }

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

    func ensureDirectoryStructure() throws {
        let fm = FileManager.default
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
        try fm.createDirectory(at: assetsURL, withIntermediateDirectories: true)
        try fm.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
    }

    /// Copy `source` into `assets/` under a fresh UUID and return a reference
    /// suitable for embedding in a slide element.
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

    func url(for asset: AssetReference) -> URL {
        assetsURL.appendingPathComponent(asset.storedFilename)
    }

    func assetExists(_ asset: AssetReference) -> Bool {
        FileManager.default.fileExists(atPath: url(for: asset).path)
    }
}
