import SwiftUI

struct HomeScreen: View {
    var body: some View {
        ZStack(alignment: .bottom){
            NavigationView{
                BirdListView()
            }
            BottomNavigationView()
        }
    }
}

#Preview {
    HomeScreen()
}
