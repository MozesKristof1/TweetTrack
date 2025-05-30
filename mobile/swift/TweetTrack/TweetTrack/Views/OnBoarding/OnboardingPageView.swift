import SwiftUI

struct OnboardingPageView: View {
    var image: String
    var title: String
    var description: String
    var showStartButton: Bool = false
    var startAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)

            Text(title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            if showStartButton {
                Button(action: {
                    startAction?()
                }) {
                    Text("Start TweetTracking")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .transition(.opacity)
            }

            Spacer(minLength: 40)
        }
    }
}
