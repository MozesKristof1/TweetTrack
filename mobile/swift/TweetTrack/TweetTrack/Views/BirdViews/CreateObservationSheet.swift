import SwiftUI
import CoreLocation

struct CreateObservationSheet: View {
    let bird: Bird
    @ObservedObject var observationViewModel: ObservationViewModel
    @ObservedObject var imageUploadViewModel: ImageUploadViewModel
    let userToken: String
    let userLocation: CLLocation?
    let onComplete: () -> Void
    
    @State private var notes: String = ""
    @State private var selectedImage: UIImage?
    @State private var caption: String = ""
    @State private var showImagePicker = false
    @State private var currentStep: ObservationStep = .createObservation
    
    @Environment(\.dismiss) private var dismiss
    
    enum ObservationStep {
        case createObservation
        case uploadImage
        case completed
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    StepIndicator(
                        step: 1,
                        title: "Observation",
                        isActive: currentStep == .createObservation,
                        isCompleted: currentStep != .createObservation
                    )
                    
                    StepIndicator(
                        step: 2,
                        title: "Photo",
                        isActive: currentStep == .uploadImage,
                        isCompleted: currentStep == .completed
                    )
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bird.name)
                                    .font(.title2.bold())
                                if let scientificName = bird.scientific_name {
                                    Text(scientificName)
                                        .font(.subheadline)
                                        .italic()
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        if currentStep == .createObservation {
                            createObservationView
                        } else if currentStep == .uploadImage {
                            uploadImageView
                        }
                    }
                    .padding()
                }
                
                VStack(spacing: 12) {
                    if currentStep == .createObservation {
                        Button(action: createObservation) {
                            HStack {
                                if observationViewModel.isCreatingObservation {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 8)
                                }
                                Text(observationViewModel.isCreatingObservation ? "Creating..." : "Create Observation")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(observationViewModel.isCreatingObservation || userLocation == nil)
                    } else if currentStep == .uploadImage {
                        Button(action: uploadImage) {
                            HStack {
                                if imageUploadViewModel.isUploading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 8)
                                }
                                Text(imageUploadViewModel.isUploading ? "Uploading..." : "Upload Photo")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedImage != nil ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(imageUploadViewModel.isUploading || selectedImage == nil)
                        
                        Button("Skip Photo") {
                            completeProcess()
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Add Observation")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: observationViewModel.createdObservation) { _, observation in
            if observation != nil {
                currentStep = .uploadImage
                imageUploadViewModel.selectedImage = selectedImage
            }
        }
        .onChange(of: imageUploadViewModel.uploadMessage) { _, message in
            if let message = message, message.contains("successfully") {
                currentStep = .completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    completeProcess()
                }
            }
        }
    }
    
    private var createObservationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.headline)
                
                if let location = userLocation {
                    Text("Lat: \(location.coordinate.latitude, specifier: "%.6f"), Lng: \(location.coordinate.longitude, specifier: "%.6f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Getting location...")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(.headline)
                
                TextField("Add any notes about this observation...", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
            if let message = observationViewModel.observationMessage {
                Text(message)
                    .foregroundColor(message.contains("successfully") ? .green : .red)
                    .font(.callout)
            }
        }
    }
    
    private var uploadImageView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add a photo to your observation")
                .font(.headline)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                
                Button("Change Photo") {
                    showImagePicker = true
                }
                .foregroundColor(.accentColor)
            } else {
                Button(action: { showImagePicker = true }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title)
                            .foregroundColor(.accentColor)
                        Text("Select Photo")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Caption (optional)")
                    .font(.headline)
                
                TextField("Add a caption for your photo...", text: $caption, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }
            
            if let message = imageUploadViewModel.uploadMessage {
                Text(message)
                    .foregroundColor(message.contains("successfully") ? .green : .red)
                    .font(.callout)
            }
        }
    }
    
    private func createObservation() {
        guard let location = userLocation else { return }
        
        Task {
            await observationViewModel.createObservation(
                bird: bird,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                notes: notes.isEmpty ? nil : notes,
                token: userToken
            )
        }
    }
    
    private func uploadImage() {
        guard let observation = observationViewModel.createdObservation else { return }
        
        imageUploadViewModel.selectedImage = selectedImage
        Task {
            await imageUploadViewModel.uploadImage(
                observationId: observation.id,
                token: userToken,
                caption: caption.isEmpty ? nil : caption
            )
        }
    }
    
    private func completeProcess() {
        onComplete()
        dismiss()
    }
}
