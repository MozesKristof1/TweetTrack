import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false

    var body: some View {
        TabView {
            OnboardingPageView(
                image: "waveform.badge.mic",
                title: "Record Bird Sounds",
                description: "Capture chirps in the wild with high-quality sound recordings."
            )
            OnboardingPageView(
                image: "binoculars.fill",
                title: "Identify Species",
                description: "Using AI that will help you recognize the birds by sound."
            )
            OnboardingPageView(
                image: "map.fill",
                title: "Explore & Share",
                description: "Discover bird hotspots near you or share your finds with the TweetTrack community.",
                showStartButton: true,
                startAction: {
                    hasSeenOnboarding = true
                }
            )
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}
