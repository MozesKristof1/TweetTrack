import AVFoundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers


@MainActor
class SoundUploadViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var uploadMessage: String?
    @Published var selectedSoundURL: URL?
    @Published var soundDuration: TimeInterval = 0
    @Published var isPlaying = false
    @Published var selectedBirdSounds = Set<UUID>()
    
    private var audioPlayer: AVAudioPlayer?
    
    func uploadSound(
        observationId: UUID,
        token: String,
        identified: Bool = false
    ) async {
        guard let soundURL = selectedSoundURL else {
            uploadMessage = "No sound file selected"
            return
        }
        
        isUploading = true
        uploadMessage = nil
        
        let boundary = UUID().uuidString
        let urlString = "\(Api.observations)/\(observationId)/sounds"
        
        guard let url = URL(string: urlString) else {
            uploadMessage = "Invalid URL"
            isUploading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = soundURL.lastPathComponent
        let contentType = "audio/mp4"

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        
        do {
            let fileData = try Data(contentsOf: soundURL)
            body.append(fileData)
        } catch {
            uploadMessage = "Error reading sound file: \(error.localizedDescription)"
            isUploading = false
            return
        }

        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"identified\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(identified)".data(using: .utf8)!)
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                uploadMessage = "No response from server"
                isUploading = false
                return
            }
            
            if httpResponse.statusCode == 201 {
                uploadMessage = "Sound uploaded successfully!"
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                uploadMessage = "Failed to upload sound: \(errorText)"
            }
        } catch {
            uploadMessage = "Error uploading sound: \(error.localizedDescription)"
        }
        
        isUploading = false
    }
    
    func uploadBirdSound(
        birdSound: BirdSoundItem,
        observationId: UUID,
        token: String,
        identified: Bool = false
    ) async {
        guard checkIfPathExists(path: birdSound.audioDataPath) else {
            uploadMessage = "Audio file not found at path: \(birdSound.audioDataPath)"
            return
        }
        
        isUploading = true
        uploadMessage = nil
        
        let boundary = UUID().uuidString
        let urlString = "\(Api.observations)/\(observationId)/sounds"
        
        guard let url = URL(string: urlString) else {
            uploadMessage = "Invalid URL"
            isUploading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let soundURL = URL(fileURLWithPath: birdSound.audioDataPath)
        let filename = soundURL.lastPathComponent
        
        let contentType: String
        switch soundURL.pathExtension.lowercased() {
        case "mp3":
            contentType = "audio/mp3"
        case "wav":
            contentType = "audio/wav"
        case "m4a":
            contentType = "audio/m4a"
        case "mp4":
            contentType = "audio/mp4"
        case "ogg":
            contentType = "audio/ogg"
        default:
            contentType = "audio/mp4"
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        
        do {
            let fileData = try Data(contentsOf: soundURL)
            body.append(fileData)
        } catch {
            uploadMessage = "Error reading sound file: \(error.localizedDescription)"
            isUploading = false
            return
        }
        
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"identified\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(identified)".data(using: .utf8)!)
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                uploadMessage = "No response from server"
                isUploading = false
                return
            }
            
            if httpResponse.statusCode == 201 {
                uploadMessage = "Sound uploaded successfully!"
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                uploadMessage = "Failed to upload sound: \(errorText)"
            }
        } catch {
            uploadMessage = "Error uploading sound: \(error.localizedDescription)"
        }
        
        isUploading = false
    }
    
    func loadSoundDuration() {
        guard let soundURL = selectedSoundURL else { return }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundDuration = audioPlayer.duration
        } catch {
            print("Error loading sound duration: \(error.localizedDescription)")
        }
    }
    
    func toggleBirdSoundSelection(_ soundId: UUID) {
        if selectedBirdSounds.contains(soundId) {
            selectedBirdSounds.remove(soundId)
        } else {
            selectedBirdSounds.insert(soundId)
        }
    }
    
    private func checkIfPathExists(path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}


struct SoundPicker: UIViewControllerRepresentable {
    @Binding var selectedSoundURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType.mp3,
                UTType.wav,
                UTType.mpeg4Audio
            ],
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: SoundPicker
        
        init(_ parent: SoundPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedSoundURL = url
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
