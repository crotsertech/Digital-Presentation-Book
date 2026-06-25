import Foundation
import SwiftUI
import CoreText
import CoreGraphics

// Programmatically discovers and registers every `.otf`/`.ttf` in the bundle.
// We do this in code (rather than via Info.plist `UIAppFonts`) because Xcode
// synchronized groups can land files at unpredictable bundle paths, so a
// hard-coded plist entry would silently miss them.

@MainActor
enum FontCatalog {

    private(set) static var customFontPostScriptNames: [String] = []
    private(set) static var hasRegistered: Bool = false

    static var pickerOptions: [Option] {
        var options: [Option] = [Option(displayName: "System", postScriptName: nil)]
        for name in customFontPostScriptNames {
            options.append(Option(displayName: name, postScriptName: name))
        }
        return options
    }

    static func register() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let extensions = ["otf", "ttf", "OTF", "TTF"]
        var urls: Set<URL> = []
        for ext in extensions {
            if let found = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                urls.formUnion(found)
            }
            // Synced groups sometimes land resources at a sub-path rather
            // than the bundle root; check the Fonts subdirectory too.
            if let found = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") {
                urls.formUnion(found)
            }
        }

        var names: Set<String> = []
        for url in urls {
            guard
                let dataProvider = CGDataProvider(url: url as CFURL),
                let cgFont = CGFont(dataProvider),
                let postScript = cgFont.postScriptName as String?
            else { continue }

            if !names.contains(postScript) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    names.insert(postScript)
                } else {
                    // "Already registered" failure: still want the name in
                    // the picker, so look it up via the system catalogue.
                    if let existing = CTFontManagerCopyAvailablePostScriptNames() as? [String],
                       existing.contains(postScript) {
                        names.insert(postScript)
                    }
                    error?.release()
                }
            }
        }

        customFontPostScriptNames = names.sorted()
    }

    struct Option: Identifiable, Hashable {
        let displayName: String
        let postScriptName: String?

        var id: String { postScriptName ?? "__system__" }
    }

    static func font(family: String?, size: CGFloat) -> Font {
        if let family, !family.isEmpty {
            return .custom(family, size: size)
        }
        return .system(size: size)
    }
}
