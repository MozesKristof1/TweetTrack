import SwiftUI
import Foundation

struct UserImageCard: View {
    let imageData: UserImageData
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 150, height: 150)
                    .shadow(radius: 4)

                if let image = uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .transition(.opacity.combined(with: .scale))
                } else if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if let caption = imageData.caption, !caption.isEmpty {
                    Text("“\(caption)”")
                        .font(.caption)
                        .lineLimit(2)
                }

                Text(formatDate(imageData.observed_at))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 150, alignment: .leading)
        }
        .onAppear { loadImage() }
    }

    private func loadImage() {
        guard let imageData = Data(base64Encoded: imageData.base64_image),
              let image = UIImage(data: imageData) else {
            isLoading = false
            return
        }
        DispatchQueue.main.async {
            self.uiImage = image
            self.isLoading = false
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}
