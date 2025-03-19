import SwiftUI

struct SoundCardView: View {
    let sound: BirdSoundItem
    let onDelete: () -> Void
    let onPlay: () -> Void
    let onStop: () -> Void
    
    @State var isPlaying: Bool = false
    
    var body: some View {
        HStack {
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .padding()
                    .foregroundStyle(.red)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(sound.title)
                .padding()
            
            Spacer()
            
            Button(action: {
                if isPlaying {
                    onStop()
                } else {
                    onPlay()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "stop.circle" : "speaker.wave.2.circle")
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}
