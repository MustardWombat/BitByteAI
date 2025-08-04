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
            Text("Wouldd you like to sign in so your data syncs in iCloud? You can skip if you prefer to keep data only on this device.")
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

struct MultiPageSignInView: View {
    @State private var selection: Int = 0
    var onSignIn: () -> Void
    var onSkip: () -> Void

    var body: some View {
        TabView(selection: $selection) {
            // Page 1: Welcome
            VStack(spacing: 20) {
                Text("Welcome to BitByte")
                    .font(.largeTitle)
                    .bold()
                Text("Your data, seamlessly synchronized across devices with iCloud.")
                    .multilineTextAlignment(.center)
                    .padding()
                Button("Get Started") {
                    withAnimation { selection = 1 }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .tag(0)
            .padding()

            // Page 2: Existing SignInPromptView
            SignInPromptView(onSignIn: onSignIn, onSkip: onSkip)
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}

struct MultiPageSignInView_Previews: PreviewProvider {
    static var previews: some View {
        MultiPageSignInView(onSignIn: {}, onSkip: {})
    }
}
