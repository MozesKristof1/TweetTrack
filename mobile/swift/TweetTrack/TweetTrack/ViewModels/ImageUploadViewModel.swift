import Foundation
import UIKit

@MainActor
class ImageUploadViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isUploading = false
    @Published var uploadMessage: String?

    func uploadImage(observationId: UUID, token: String, caption: String?) async {
        guard let image = selectedImage else {
            uploadMessage = "No image selected"
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadMessage = "Image conversion failed"
            return
        }

        isUploading = true
        uploadMessage = nil
        
        let url = URL(string: Api.userObservationsImages(observationId.uuidString))!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n".data(using: .utf8)!)

        if let caption = caption, !caption.isEmpty {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(caption)\r\n".data(using: .utf8)!)
        }

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                uploadMessage = "No response from server"
                isUploading = false
                return
            }

            if httpResponse.statusCode == 201 {
                uploadMessage = "Image uploaded successfully!"
            } else {
                let errorText = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                uploadMessage = "Upload failed: \(errorText)"
            }
        } catch {
            uploadMessage = "Upload error: \(error.localizedDescription)"
        }
        
        isUploading = false
    }
}
