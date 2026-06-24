import Foundation

/// Pointer into the package's `assets/` directory. Files are stored by UUID
/// so the original filename can be anything and collisions never occur.
struct AssetReference: Codable, Hashable, Sendable {
    var id: UUID
    var originalName: String
    var fileExtension: String
    var mimeType: String
    var byteSize: Int

    var storedFilename: String {
        "\(id.uuidString).\(fileExtension)"
    }
}
