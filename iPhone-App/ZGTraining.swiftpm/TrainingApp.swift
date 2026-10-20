import SwiftUI

@main
struct TrainingApp: App {
    @StateObject private var store = TrainingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
