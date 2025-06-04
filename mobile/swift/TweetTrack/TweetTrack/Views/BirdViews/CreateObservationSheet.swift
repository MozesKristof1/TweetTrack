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
    @State private var currentStep: ObservationStep = .selectObservationType
    @State private var observationType: ObservationType = .createNew
    @State private var selectedExistingObservation: BirdObservationResponse?
    
    @Environment(\.dismiss) private var dismiss
    
    enum ObservationStep {
        case selectObservationType
        case createObservation
        case selectExistingObservation
        case uploadImage
        case completed
    }
    
    enum ObservationType {
        case createNew
        case useExisting
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Step indicator
                HStack(spacing: 15) {
                    StepIndicator(
                        step: 1,
                        title: "Choose",
                        isActive: currentStep == .selectObservationType,
                        isCompleted: currentStep != .selectObservationType
                    )
                    
                    StepIndicator(
                        step: 2,
                        title: observationType == .createNew ? "Create" : "Select",
                        isActive: currentStep == .createObservation || currentStep == .selectExistingObservation,
                        isCompleted: currentStep == .uploadImage || currentStep == .completed
                    )
                    
                    StepIndicator(
                        step: 3,
                        title: "Photo",
                        isActive: currentStep == .uploadImage,
                        isCompleted: currentStep == .completed
                    )
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Bird info header
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
                        
                        // Step content
                        switch currentStep {
                        case .selectObservationType:
                            selectObservationTypeView
                        case .createObservation:
                            createObservationView
                        case .selectExistingObservation:
                            selectExistingObservationView
                        case .uploadImage:
                            uploadImageView
                        case .completed:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    switch currentStep {
                    case .selectObservationType:
                        Button("Continue") {
                            if observationType == .createNew {
                                currentStep = .createObservation
                            } else {
                                // Load existing observations when selecting this option
                                Task {
                                    await observationViewModel.loadUserObservations(
                                        birdEBirdId: bird.ebird_id!,
                                        token: userToken
                                    )
                                }
                                currentStep = .selectExistingObservation
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                    case .createObservation:
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
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(observationViewModel.isCreatingObservation || userLocation == nil)
                        
                    case .selectExistingObservation:
                        Button("Use Selected Observation") {
                            currentStep = .uploadImage
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(selectedExistingObservation == nil)
                        
                    case .uploadImage:
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
                        }
                        .buttonStyle(PrimaryButtonStyle(isEnabled: selectedImage != nil))
                        .disabled(imageUploadViewModel.isUploading || selectedImage == nil)
                        
                        Button("Skip Photo") {
                            completeProcess()
                        }
                        .foregroundColor(.secondary)
                        
                    case .completed:
                        EmptyView()
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Add Photo to Observation")
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
    
    private var selectObservationTypeView: some View {
        VStack(spacing: 16) {
            Text("Choose an option")
                .font(.headline)
            
            VStack(spacing: 12) {
                Button(action: {
                    observationType = .createNew
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create New Observation")
                                .font(.headline)
                            Text("Record a new sighting of this bird")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: observationType == .createNew ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(observationType == .createNew ? .accentColor : .gray)
                    }
                    .padding()
                    .background(observationType == .createNew ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
                
                Button(action: {
                    observationType = .useExisting
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add to Existing Observation")
                                .font(.headline)
                            Text("Add a photo to one of your previous sightings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: observationType == .useExisting ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(observationType == .useExisting ? .accentColor : .gray)
                    }
                    .padding()
                    .background(observationType == .useExisting ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    .cornerRadius(12)
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    private var selectExistingObservationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select an existing observation")
                .font(.headline)
            
            if observationViewModel.isLoadingObservations {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading your observations...")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if observationViewModel.userObservations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "binoculars")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("No previous observations found for this bird")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create New Instead") {
                        observationType = .createNew
                        currentStep = .createObservation
                    }
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(observationViewModel.userObservations, id: \.id) { observation in
                        Button(action: {
                            selectedExistingObservation = observation
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(DateFormatter.shortDate.string(from: observation.observed_at))
                                        .font(.headline)
                                    
                                    if let notes = observation.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Text("Lat: \(observation.latitude, specifier: "%.4f"), Lng: \(observation.longitude, specifier: "%.4f")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: selectedExistingObservation?.id == observation.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedExistingObservation?.id == observation.id ? .accentColor : .gray)
                            }
                            .padding()
                            .background(selectedExistingObservation?.id == observation.id ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            
            if let message = observationViewModel.observationMessage {
                Text(message)
                    .foregroundColor(message.contains("successfully") ? .green : .red)
                    .font(.callout)
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
        let observationId: UUID
        
        if let createdObservation = observationViewModel.createdObservation {
            observationId = createdObservation.id
        } else if let selectedObservation = selectedExistingObservation {
            observationId = selectedObservation.id
        } else {
            return
        }
        
        imageUploadViewModel.selectedImage = selectedImage
        Task {
            await imageUploadViewModel.uploadImage(
                observationId: observationId,
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

// Helper button style
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// Helper date formatter
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
