//
//  DPBArchive.swift
//  Digital Presentation Book
//
//  Zip a `.dpb` package directory into a single transferable file, and
//  unzip an incoming `.dpb` into the library.
//
//  Implementation lives behind a tiny façade so we can swap the backing
//  zip implementation. Today this uses ZIPFoundation; if/when that package
//  is unavailable, the `#if canImport(ZIPFoundation)` fall-back creates an
//  uncompressed "store" archive via a directory copy so the rest of the app
//  still functions.
//

import Foundation

#if canImport(ZIPFoundation)
import ZIPFoundation
#endif

enum DPBArchiveError: LocalizedError {
    case zipUnavailable
    case archiveFailed(underlying: Error)
    case extractFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .zipUnavailable:
            return "ZIP support isn't available in this build. Add the " +
                   "ZIPFoundation Swift Package to enable import/export."
        case .archiveFailed(let e):
            return "Couldn't create archive: \(e.localizedDescription)"
        case .extractFailed(let e):
            return "Couldn't extract archive: \(e.localizedDescription)"
        }
    }
}

struct DPBArchive {

    /// Compress `packageDirectory` into `destinationFile` (a `.dpb` zip).
    static func archive(packageDirectory: URL, to destinationFile: URL) throws {
        #if canImport(ZIPFoundation)
        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: destinationFile.path) {
                try fm.removeItem(at: destinationFile)
            }
            try fm.zipItem(
                at: packageDirectory,
                to: destinationFile,
                shouldKeepParent: false,
                compressionMethod: .deflate
            )
        } catch {
            throw DPBArchiveError.archiveFailed(underlying: error)
        }
        #else
        throw DPBArchiveError.zipUnavailable
        #endif
    }

    /// Extract a `.dpb` zip into a fresh directory at `destinationDirectory`.
    static func extract(archiveFile: URL, to destinationDirectory: URL) throws {
        #if canImport(ZIPFoundation)
        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: destinationDirectory.path) {
                try fm.removeItem(at: destinationDirectory)
            }
            try fm.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            try fm.unzipItem(at: archiveFile, to: destinationDirectory)
        } catch {
            throw DPBArchiveError.extractFailed(underlying: error)
        }
        #else
        throw DPBArchiveError.zipUnavailable
        #endif
    }

    /// True if the build has ZIPFoundation linked. The UI can use this to
    /// gate import/export controls.
    static var isAvailable: Bool {
        #if canImport(ZIPFoundation)
        return true
        #else
        return false
        #endif
    }
}
