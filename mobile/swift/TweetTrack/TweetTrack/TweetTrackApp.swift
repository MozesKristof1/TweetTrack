import SwiftUI
import SwiftData

@main
struct TweetTrackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: BirdSoundItem.self)
    }
}
