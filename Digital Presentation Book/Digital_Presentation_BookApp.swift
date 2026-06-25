import SwiftUI

@main
struct Digital_Presentation_BookApp: App {
    @State private var store = BookStore()

    init() {
        FontCatalog.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task { store.refresh() }
        }
    }
}
