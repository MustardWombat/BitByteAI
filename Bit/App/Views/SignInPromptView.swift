import SwiftUI
import AuthenticationServices

struct SignInPromptView: View {
    // Callbacks to report the choice.
    var onSignIn: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome!")
                .font(.largeTitle)
                .bold()
            Text("Would you like to sign in so your data syncs in iCloud? You can skip if you prefer to keep data only on this device.")
                .multilineTextAlignment(.center)
                .padding()
            Button("Sign In") {
                onSignIn()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            Button("Skip") {
                onSkip()
            }
            .padding()
            .buttonStyle(TransparentButtonStyle())
            .foregroundColor(.white)
        }
        .padding()
    }
}
