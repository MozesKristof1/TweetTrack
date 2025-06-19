import SwiftUI

struct MyObservationsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var observationViewModel = ObservationViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if observationViewModel.isLoadingObservations {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading your observations...")
                            .padding(.top)
                            .foregroundColor(.primary)
                    }
                } else if observationViewModel.myObservations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "binoculars")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Observations Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start exploring and recording your bird sightings!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if let message = observationViewModel.observationMessage {
                            Text(message)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    List(observationViewModel.myObservations, id: \.id) { observation in
                        ObservationRowView(observation: observation)
                    }
                    .refreshable {
                        if let token = authService.accessToken {
                            await observationViewModel.loadMyObservations(token: token)
                        }
                    }
                }
            }
            .navigationTitle("My Observations")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            if let token = authService.accessToken {
                await observationViewModel.loadMyObservations(token: token)
            }
        }
    }
}
