import SwiftUI

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
