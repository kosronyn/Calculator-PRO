import SwiftUI
@main
struct CalculatorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(width: 1000, height: 500) // Locks exact size
        }
        .windowResizability(.contentSize) // Prevents user resizing
    }
}
