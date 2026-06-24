//
//  ContentView.swift
//  Digital Presentation Book
//
//  Root view — for now this is just the library. The editor will be a
//  separate route added in Phase 2.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    ContentView()
        .environment(BookStore())
}
