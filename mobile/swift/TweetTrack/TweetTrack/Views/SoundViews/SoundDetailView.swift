import SwiftUI

struct SoundDetailView: View {
    let sound: BirdSoundItem
    var body: some View {
        Text(sound.title)
    }
}
