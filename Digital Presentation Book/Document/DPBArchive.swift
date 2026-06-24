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

/// Thin façade over ZIPFoundation. Wrapped so the rest of the app doesn't
/// touch the dependency directly, and so callers can probe `isAvailable`
/// before enabling import/export controls.
struct DPBArchive {

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

    static var isAvailable: Bool {
        #if canImport(ZIPFoundation)
        return true
        #else
        return false
        #endif
    }
}
