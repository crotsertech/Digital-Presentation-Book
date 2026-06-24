//
//  Digital_Presentation_BookApp.swift
//  Digital Presentation Book
//

import SwiftUI

@main
struct Digital_Presentation_BookApp: App {
    @State private var store = BookStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { store.refresh() }
        }
    }
}
