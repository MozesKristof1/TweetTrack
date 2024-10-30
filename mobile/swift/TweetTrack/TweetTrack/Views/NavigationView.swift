import SwiftUI

enum Tab {
    case home, sound, profile
}

struct CustomNavigationView: View {
    @Binding var selectedTab: Tab
    var onTabSelected: ((Tab) -> Void)?

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    selectedTab = .home
                    onTabSelected?(.home)
                }) {
                    Image(systemName: "bird.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    selectedTab = .sound
                    onTabSelected?(.sound)
                }) {
                    Image(systemName: "waveform")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity)

                Button(action: {
                    selectedTab = .profile
                    onTabSelected?(.profile)
                }) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 2)
            .background(Color(.secondarySystemBackground))
        }
    }
}

#Preview {
    CustomNavigationView(selectedTab: .constant(.home), onTabSelected: { tab in
        print("\(tab) tapped")
    })
}
