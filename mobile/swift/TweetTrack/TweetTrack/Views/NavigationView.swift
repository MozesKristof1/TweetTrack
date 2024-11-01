import SwiftUI

struct BottomNavigationView: View {
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    print("Home tapped")
                }) {
                    Image(systemName: "bird.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    print("Sound tapped")
                }) {
                    Image(systemName: "waveform")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    print("Profile tapped")
                }) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 0)
            .background(Color(.secondarySystemBackground))
        }
    }
}

#Preview {
    BottomNavigationView()
}
