import SwiftUI

struct SessionEndedOverlay: View {
    let studiedMinutes: Int
    let studiedSeconds: Int
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("⏰ Time's Up!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
            Text("You studied for \(studiedMinutes) minutes and \(studiedSeconds) seconds.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
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
}
