import SwiftUI

struct BirdCardView: View {
    let bird: Bird

    var body: some View {
        HStack {
            if let data = Data(base64Encoded: bird.base64Picture, options: .ignoreUnknownCharacters),
               let uiImage = UIImage(data: data)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(25)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading) {
                Text(bird.name)
                    .font(.headline)
                Text(bird.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .lineSpacing(0.5)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
