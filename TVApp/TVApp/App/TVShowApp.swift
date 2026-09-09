import SwiftUI

@main
struct TVShowApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ShowListView()
            }
        }
    }
}
