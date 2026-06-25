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

    /// Asset catalog first; then a loose `DPB_icon.png` in the bundle root
    /// or `Icons/` subdirectory (synced groups preserve subdirectories).
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
