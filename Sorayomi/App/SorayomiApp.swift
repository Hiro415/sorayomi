import SwiftUI

@main
struct SorayomiApp: App {
    @State private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appEnvironment)
        }
    }
}
