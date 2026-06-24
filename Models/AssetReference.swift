//
//  AssetReference.swift
//  Digital Presentation Book
//
//  Pointer from the manifest into the `assets/` folder of a .dpb package.
//  Assets are stored by UUID so the original filename can be anything and
//  collisions never occur.
//

import Foundation

/// A reference to a binary blob inside the package's `assets/` directory.
struct AssetReference: Codable, Hashable, Sendable {
    /// Stable UUID; combined with `fileExtension` becomes the on-disk filename.
    var id: UUID
    /// The asset's original filename (display only).
    var originalName: String
    /// File extension without the dot, lowercase. e.g. "jpg", "mp4".
    var fileExtension: String
    /// IANA media type. Useful for AVKit and import validation.
    var mimeType: String
    /// File size in bytes at the time the asset was added.
    var byteSize: Int

    /// The filename used inside the package's `assets/` directory.
    var storedFilename: String {
        "\(id.uuidString).\(fileExtension)"
    }
}
