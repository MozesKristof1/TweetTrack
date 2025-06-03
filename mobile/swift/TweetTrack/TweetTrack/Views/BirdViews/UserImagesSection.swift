import SwiftUI

struct UserImagesSection: View {
    let images: [UserImageData]
    let isLoading: Bool
    let errorMessage: String?
    let onUploadTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().padding(.top, 8)

            HStack {
                Text("Community Photos")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !images.isEmpty {
                    Text("\(images.count) photo\(images.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: onUploadTapped) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            Group {
                if isLoading {
                    HStack(spacing: 10) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1)
                        Text("Loading photos...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if let errorMessage = errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundColor(.orange)
                        .padding(.horizontal)
                } else if images.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No community photos yet")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Text("Be the first to share a photo!")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(images, id: \.image_id) { imageData in
                                UserImageCard(imageData: imageData)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .animation(.easeInOut, value: isLoading)
        }
    }
}
