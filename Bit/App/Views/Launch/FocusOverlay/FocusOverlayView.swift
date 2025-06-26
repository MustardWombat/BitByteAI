import SwiftUI

struct FocusOverlayView: View {
    @Binding var isActive: Bool
    @ObservedObject var timerModel: StudyTimerModel

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 20) {
                Image(systemName: "rocket.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .scaleEffect(1.3)
                Text(formatTime(timerModel.timeRemaining))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(timerModel.isTimerRunning ? .green : .red)
                Button("Land") {
                    withAnimation(.spring()) {
                        timerModel.stopTimer()
                        isActive = false
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .ignoresSafeArea()
        .onAppear {
            timerModel.startTimer(for: timerModel.timeRemaining)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
