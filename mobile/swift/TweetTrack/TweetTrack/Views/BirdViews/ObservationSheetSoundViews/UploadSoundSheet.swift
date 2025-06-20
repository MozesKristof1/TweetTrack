import SwiftUI
import SwiftData

struct UploadSoundSheet: View {
    let observationId: UUID
    let userToken: String
    let onComplete: () -> Void
    
    @StateObject private var soundUploadViewModel = SoundUploadViewModel()
    @State private var showSoundPicker = false
    @State private var identified = false
    @State private var selectedTab = 0
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var context
    @Query private var birdSounds: [BirdSoundItem] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    
                    Text("Upload Sound Recording")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Add an audio recording to your bird observation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Picker("Source", selection: $selectedTab) {
                    Text("From Files").tag(0)
                    Text("My Library").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            if let soundURL = soundUploadViewModel.selectedSoundURL {
                                selectedSoundView(soundURL: soundURL)
                            } else {
                                fileSelectionView
                            }
                        } else {
                            // Bird sounds library section
                            birdSoundsLibraryView
                        }
                        
                        if hasSelectedContent {
                            VStack(spacing: 8) {
                                Toggle("Mark as Identified", isOn: $identified)
                                    .toggleStyle(SwitchToggleStyle())
                                
                                Text("Check this if the bird species in the recording has been identified")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        if let message = soundUploadViewModel.uploadMessage {
                            Text(message)
                                .foregroundColor(message.contains("successfully") ? .green : .red)
                                .font(.callout)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                
                VStack(spacing: 12) {
                    Button(action: uploadSelectedSounds) {
                        HStack {
                            if soundUploadViewModel.isUploading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 8)
                            }
                            Text(soundUploadViewModel.isUploading ? "Uploading..." : uploadButtonText)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasSelectedContent ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(soundUploadViewModel.isUploading || !hasSelectedContent)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Add Sound")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPicker(selectedSoundURL: $soundUploadViewModel.selectedSoundURL)
        }
        .onChange(of: soundUploadViewModel.selectedSoundURL) { _, newURL in
            if newURL != nil {
                soundUploadViewModel.loadSoundDuration()
                soundUploadViewModel.selectedBirdSounds.removeAll()
            }
        }
        .onChange(of: soundUploadViewModel.uploadMessage) { _, message in
            if let message = message, message.contains("successfully") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onComplete()
                    dismiss()
                }
            }
        }
    }
    
    private var hasSelectedContent: Bool {
        return soundUploadViewModel.selectedSoundURL != nil || !soundUploadViewModel.selectedBirdSounds.isEmpty
    }
    
    private var uploadButtonText: String {
        if selectedTab == 0 {
            return "Upload Sound"
        } else {
            let count = soundUploadViewModel.selectedBirdSounds.count
            return count > 1 ? "Upload \(count) Sounds" : "Upload Sound"
        }
    }
    
    private var fileSelectionView: some View {
        Button(action: { showSoundPicker = true }) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)

                VStack(spacing: 8) {
                    Text("Select Audio File")
                        .font(.headline)
                        .foregroundColor(.accentColor)

                    Text("Supported formats: MP3, WAV, M4A, MP4, OGG")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(40)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
        }
    }
    
    private var birdSoundsLibraryView: some View {
        VStack(spacing: 16) {
            if birdSounds.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Sounds in Library")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your recorded bird sounds will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(birdSounds) { sound in
                        BirdSoundRow(
                            sound: sound,
                            isSelected: soundUploadViewModel.selectedBirdSounds.contains(sound.id),
                            onToggle: {
                                soundUploadViewModel.toggleBirdSoundSelection(sound.id)
                                if !soundUploadViewModel.selectedBirdSounds.isEmpty {
                                    soundUploadViewModel.selectedSoundURL = nil
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func selectedSoundView(soundURL: URL) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.accentColor)
                    Text(soundURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                }
                
                HStack {
                    Text("Duration: \(formatDuration(soundUploadViewModel.soundDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(soundURL.pathExtension.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Button("Choose Different File") {
                soundUploadViewModel.selectedSoundURL = nil
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    private func uploadSelectedSounds() {
        Task {
            if selectedTab == 0, soundUploadViewModel.selectedSoundURL != nil {
                // Upload from file picker
                await soundUploadViewModel.uploadSound(
                    observationId: observationId,
                    token: userToken,
                    identified: identified
                )
            } else if selectedTab == 1, !soundUploadViewModel.selectedBirdSounds.isEmpty {
                // Upload from user recordongs
                for soundId in soundUploadViewModel.selectedBirdSounds {
                    if let birdSound = birdSounds.first(where: { $0.id == soundId }) {
                        await soundUploadViewModel.uploadBirdSound(
                            birdSound: birdSound,
                            observationId: observationId,
                            token: userToken,
                            identified: identified
                        )
                        
                        if let message = soundUploadViewModel.uploadMessage,
                           !message.contains("successfully") {
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func checkIfPathExists(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
