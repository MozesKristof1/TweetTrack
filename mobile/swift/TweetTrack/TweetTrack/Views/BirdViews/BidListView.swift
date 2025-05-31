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
                if birdFetcher.birds.isEmpty && !isSearching {
                    VStack {
                        ProgressView()
                            .padding(.bottom)
                            .opacity(birdFetcher.birds.isEmpty ? 1 : 0)
                        Text("Loading birds...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.top, 50)

                } else if filteredBirds.isEmpty && !searchText.isEmpty {
                    Text("No birds found for \"\(searchText)\"")
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
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
            }
            .navigationTitle(isSearching ? "" : "Birds")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        print("asdf")
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    Button {
                        print("asd")
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                if isSearching {
                    ToolbarItem(placement: .principal) {
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
            .onAppear {
                if birdFetcher.birds.isEmpty {
                    Task {
                        await birdFetcher.fetchBirds()
                    }
                }
            }
        }
    }
}

#Preview {
    BirdListView()
}
