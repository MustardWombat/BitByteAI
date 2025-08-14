import SwiftUI

struct SessionEndedOverlay: View {
    let studiedMinutes: Int
    let studiedSeconds: Int
    let xpEarned: Int
    let coinsEarned: Int
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("⏰ Time's Up!")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                Text("You studied for \(studiedMinutes) minutes and \(studiedSeconds) seconds.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                // Earned stats section
                VStack(spacing: 8) {
                    Text("XP Earned: \(xpEarned)")
                        .font(.title3)
                        .foregroundColor(.yellow)

                    Text("Coins Earned: \(coinsEarned)")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                .padding(.top, 10)

                Button("Awesome!") {
                    onDismiss()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .ignoresSafeArea(edges: .bottom)
    }
}
