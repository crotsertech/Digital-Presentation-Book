//
//  FontCatalog.swift
//  Digital Presentation Book
//
//  Programmatically discovers and registers every `.otf` / `.ttf` file
//  in the app bundle and exposes the resulting PostScript names to the
//  rest of the app. Doing this in code (instead of Info.plist's
//  `UIAppFonts`) sidesteps the synchronized-group quirk where fonts in
//  `Resources/Fonts/` may not land at predictable bundle paths.
//

import Foundation
import SwiftUI
import CoreText
import CoreGraphics

@MainActor
enum FontCatalog {

    /// PostScript names of every custom font the app successfully
    /// registered, sorted alphabetically.
    private(set) static var customFontPostScriptNames: [String] = []

    /// True after `register()` has run once.
    private(set) static var hasRegistered: Bool = false

    /// Display options for the inspector's font picker.
    static var pickerOptions: [Option] {
        var options: [Option] = [Option(displayName: "System", postScriptName: nil)]
        for name in customFontPostScriptNames {
            options.append(Option(displayName: name, postScriptName: name))
        }
        return options
    }

    /// Run once at app launch. Subsequent calls are a no-op.
    static func register() {
        guard !hasRegistered else { return }
        hasRegistered = true

        let extensions = ["otf", "ttf", "OTF", "TTF"]
        var urls: Set<URL> = []
        for ext in extensions {
            if let found = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                urls.formUnion(found)
            }
            // Some synced groups put resources at sub-paths instead of the
            // bundle root; check the `Fonts` subdirectory too just in case.
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

            // Skip if a font with this name is already known to the system
            // (avoid noisy registration errors on hot reload / re-launch).
            if !names.contains(postScript) {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    names.insert(postScript)
                } else {
                    // Registration can fail for "already registered" — in
                    // that case we still want the name surfaced.
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

    /// One row in the font picker.
    struct Option: Identifiable, Hashable {
        let displayName: String
        let postScriptName: String?

        var id: String { postScriptName ?? "__system__" }
    }

    /// Resolve a stored `fontFamily` value to a SwiftUI `Font`.
    static func font(family: String?, size: CGFloat) -> Font {
        if let family, !family.isEmpty {
            return .custom(family, size: size)
        }
        return .system(size: size)
    }
}
