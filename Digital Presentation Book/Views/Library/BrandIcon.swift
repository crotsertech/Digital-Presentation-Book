//
//  BrandIcon.swift
//  Digital Presentation Book
//
//  Loads `DPB_icon.png` from the bundle for in-app branding (nav title,
//  empty states, etc.). Falls back to a tinted SF Symbol if the asset
//  can't be found so the UI still renders cleanly.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct BrandIcon: View {
    var body: some View {
        if let image = loadedImage {
            image
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: "books.vertical.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.tint)
        }
    }

    /// Looks for `DPB_icon` in the asset catalog first, then for a loose
    /// `DPB_icon.png` anywhere in the bundle (including the `Icons`
    /// subdirectory the synced group preserves).
    private var loadedImage: Image? {
        #if canImport(UIKit)
        if let asset = UIImage(named: "DPB_icon") {
            return Image(uiImage: asset)
        }
        for subdir in [nil, "Icons", "Resources/Icons"] as [String?] {
            if let url = Bundle.main.url(
                forResource: "DPB_icon",
                withExtension: "png",
                subdirectory: subdir
            ), let img = UIImage(contentsOfFile: url.path) {
                return Image(uiImage: img)
            }
        }
        return nil
        #elseif canImport(AppKit)
        if let asset = NSImage(named: "DPB_icon") {
            return Image(nsImage: asset)
        }
        return nil
        #else
        return nil
        #endif
    }
}
