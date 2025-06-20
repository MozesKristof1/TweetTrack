import SwiftUI

struct BirdListView: View {
    @StateObject var birdFetcher = BirdFetcher()
    @State private var searchText = ""
    @State private var isSearching: Bool = false
    @FocusState private var searchFieldIsFocused: Bool

    var filteredBirds: [Bird] {
        if searchText.isEmpty {
            return birdFetcher.birds
        } else {
            return birdFetcher.birds.filter { bird in
                bird.name.localizedCaseInsensitiveContains(searchText)
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
                    BirdCardView(bird: bird)
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
                print("asdf")
            } label: {
                Image(systemName: "location.circle.fill")
            }

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
}

#Preview {
    BirdListView()
}
