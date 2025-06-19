import SwiftUI

struct UserImagesSection: View {
    let images: [UserImageData]
    let isLoading: Bool
    let errorMessage: String?
    let onUploadTapped: () -> Void
    let onImageTapped: (UIImage) -> Void
    
    private func base64ToUIImage(_ base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Community Photos")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onUploadTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Photo")
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
                .frame(height: 120)
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            } else if images.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No community photos yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Be the first to share a photo!")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, imageData in
                            Button(action: {
                                // Convert base64 string to UIImage
                                if let uiImage = base64ToUIImage(imageData.base64_image) {
                                    onImageTapped(uiImage)
                                }
                            }) {
                                if let uiImage = base64ToUIImage(imageData.base64_image) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .cornerRadius(12)
                                        .shadow(radius: 2)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(12)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

