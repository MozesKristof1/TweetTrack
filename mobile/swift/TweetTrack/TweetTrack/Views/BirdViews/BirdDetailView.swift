import MapKit
import SwiftUI

struct BirdDetailView: View {
    var bird: Bird
    let manager = CLLocationManager()
    @State private var position: MapCameraPosition =
        .userLocation(fallback: .automatic)
    @StateObject var birdLocationFetcher = BirdLocationFetcher()
    
    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack {
                        HStack {
                            Text(bird.name)
                                .font(.largeTitle)
                                .padding()
                            Button(action: {
                                print("Sound button pressed")
                            }) {
                                Image(systemName: "speaker.wave.2.circle")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .padding()
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                        
                        Text(bird.description)
                            .font(.body)
                            .padding()
                        
                        Spacer()
                        MapCardView(birdLocations: $birdLocationFetcher.birdLocation, position: $position, manager: manager)
                    }
                    .padding()
                    .onAppear {
                        Task {
                            await birdLocationFetcher.birdLocationFetcher()
                        }
                    }
                }
            }
            
            VStack {
                Spacer()
                HStack {                    
                    Button(action: {
                        print("Add button pressed")
                    }) {
                        Image(systemName: "plus.app.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding()
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    BirdListView(birdFetcher: BirdFetcher())
}
