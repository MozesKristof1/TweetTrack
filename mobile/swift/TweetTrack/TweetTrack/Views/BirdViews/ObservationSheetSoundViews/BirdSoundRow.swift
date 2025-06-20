import SwiftUI

struct BirdSoundRow: View {
    let sound: BirdSoundItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sound.title)
                    .font(.headline)
                    .lineLimit(1)
                
                
                Text(sound.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                
                HStack {
                    Text(URL(fileURLWithPath: sound.audioDataPath).pathExtension.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    if !FileManager.default.fileExists(atPath: sound.audioDataPath) {
                        Text("File not found")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(systemName: "waveform")
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}
