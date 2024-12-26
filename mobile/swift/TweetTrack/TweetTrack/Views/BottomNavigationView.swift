import SwiftUI

struct BottomNavigationView: View {
    var body: some View {
        TabView {
            NavigationView {
                BirdListView()
            }
            .tabItem {
                Label("Birds", systemImage: "bird.circle.fill")
            }
                
            NavigationView {
                SoundListView()
            }
            .tabItem {
                Label("Sound Recognition", systemImage: "waveform")
            }
              
            NavigationView {
                UserDetailView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
    }
}
#Preview {
    BottomNavigationView()
}
