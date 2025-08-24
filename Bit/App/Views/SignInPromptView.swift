import SwiftUI
import AuthenticationServices

struct SignInPromptView: View {
    var onSignIn: () -> Void
    var onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to BitByte")
                .font(.largeTitle)
                .bold()
            
            Text("Sign in with Apple to sync your data across devices and access social features.")
                .multilineTextAlignment(.center)
                .padding()
            
            #if os(iOS)
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = []
                },
                onCompletion: { result in
                    switch result {
                    case .success:
                        onSignIn()
                    case .failure:
                        break
                    }
                }
            )
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .padding(.horizontal)
            #else
            Button("Sign In") {
                onSignIn()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            #endif
            
            Button("Continue without signing in") {
                onSkip()
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.gray)
            .cornerRadius(8)
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
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}
