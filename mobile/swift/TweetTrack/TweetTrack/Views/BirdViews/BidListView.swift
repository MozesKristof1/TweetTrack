import SwiftUI
import CoreLocation

struct BirdListView: View {
    @StateObject var birdFetcher = BirdFetcher()
    @StateObject var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var isSearching: Bool = false
    @State private var nearbyBirdIds: Set<UUID> = []
    @State private var isLoadingLocation = false
    @FocusState private var searchFieldIsFocused: Bool

    var filteredBirds: [Bird] {
        let birds = if searchText.isEmpty {
            birdFetcher.birds
        } else {
            birdFetcher.birds.filter { bird in
                bird.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return birds.sorted { bird1, bird2 in
            let bird1IsNearby = nearbyBirdIds.contains(bird1.id)
            let bird2IsNearby = nearbyBirdIds.contains(bird2.id)
            
            if bird1IsNearby && !bird2IsNearby {
                return true
            } else if !bird1IsNearby && bird2IsNearby {
                return false
            } else {
                return bird1.name < bird2.name
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                content
            }
            .navigationTitle(isSearching ? "" : "Birds")
            .toolbar { toolbarContent }
            .onAppear {
                if birdFetcher.birds.isEmpty {
                    Task {
                        await birdFetcher.fetchBirds()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if birdFetcher.birds.isEmpty && !isSearching {
            loadingView
        } else if filteredBirds.isEmpty && !searchText.isEmpty {
            noResultsView
        } else {
            birdListView
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .padding(.bottom)
            Text("Loading birds...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.top, 50)
    }

    private var noResultsView: some View {
        Text("No birds found for \"\(searchText)\"")
            .foregroundColor(.secondary)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var birdListView: some View {
        LazyVStack(spacing: 10) {
            ForEach(filteredBirds) { bird in
                NavigationLink(destination: BirdDetailView(bird: bird)) {
                    BirdCardView(
                        bird: bird,
                        isNearby: nearbyBirdIds.contains(bird.id)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                Task {
                    await fetchNearbyBirds()
                }
            } label: {
                HStack {
                    if isLoadingLocation {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.circle.fill")
                    }
                }
            }
            .disabled(isLoadingLocation)
        }

        if isSearching {
            ToolbarItem(placement: .principal) {
                searchField
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    withAnimation(.snappy(duration: 0.2)) {
                        searchText = ""
                        isSearching = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
            }
        } else {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isSearching = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .trailing)))
            }
        }
    }

    private var searchField: some View {
        TextField("Search by bird name", text: $searchText)
            .textFieldStyle(.plain)
            .focused($searchFieldIsFocused)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(UIColor.systemGray6))
            .clipShape(Capsule())
            .frame(minHeight: 36, idealHeight: 36, maxHeight: 36)
            .transition(AnyTransition.opacity.combined(with: .offset(x: 0, y: -20)))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    searchFieldIsFocused = true
                }
            }
    }
    
    private func fetchNearbyBirds() async {
        guard !isLoadingLocation else { return }
        
        isLoadingLocation = true
        
        if locationManager.location == nil {
            locationManager.requestLocation()
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        guard let location = locationManager.location else {
            print("Location not available")
            isLoadingLocation = false
            return
        }
        
        let radiusInDegrees = 0.1
        let minLat = location.coordinate.latitude - radiusInDegrees
        let maxLat = location.coordinate.latitude + radiusInDegrees
        let minLng = location.coordinate.longitude - radiusInDegrees
        let maxLng = location.coordinate.longitude + radiusInDegrees
        
        let urlString = Api.birdLocationsInArea(
            minLat: minLat,
            maxLat: maxLat,
            minLng: minLng,
            maxLng: maxLng
        )
        print("Requesting URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            isLoadingLocation = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("API Response: \(jsonString)")
            }
            
            if let jsonString = String(data: data, encoding: .utf8),
               jsonString.contains("\"detail\"") {
                await MainActor.run {
                    isLoadingLocation = false
                }
                return
            }
            
            var birdLocations: [BirdLocation] = []
            
            do {
                birdLocations = try JSONDecoder().decode([BirdLocation].self, from: data)
            } catch {
                do {
                    let wrapper = try JSONDecoder().decode(DataWrapper.self, from: data)
                    birdLocations = wrapper.data
                } catch {
                    do {
                        let wrapper = try JSONDecoder().decode(LocationsWrapper.self, from: data)
                        birdLocations = wrapper.locations
                    } catch {
                        do {
                            let wrapper = try JSONDecoder().decode(ResultsWrapper.self, from: data)
                            birdLocations = wrapper.results
                        } catch {
                            throw error
                        }
                    }
                }
            }
            
            await MainActor.run {
                nearbyBirdIds = Set(birdLocations.map { $0.birdId })
                isLoadingLocation = false
                print("Found \(birdLocations.count) bird locations nearby")
            }
        } catch {
            print("Error fetching nearby birds: \(error)")
            await MainActor.run {
                isLoadingLocation = false
            }
        }
    }
}

struct DataWrapper: Codable {
    let data: [BirdLocation]
}

struct LocationsWrapper: Codable {
    let locations: [BirdLocation]
}

struct ResultsWrapper: Codable {
    let results: [BirdLocation]
}
