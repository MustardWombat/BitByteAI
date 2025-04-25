import SwiftUI

struct StudySessionView: View {
    @EnvironmentObject var timerModel: StudyTimerModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.dismiss) var dismiss  // Added dismiss environment

    var body: some View {
        ZStack {
            // Dimmed background prevents interaction with underlying views
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            // Central popup card containing the study clock
            VStack(spacing: 20) {
                Text("Study Session")
                    .font(.title)
                    .foregroundColor(.white)
                Text(formatTime(timerModel.timeRemaining))
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Button(action: {
                    timerModel.stopTimer()
                    dismiss()  // Dismiss popup when session ends
                }) {
                    Text("End Session")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 40)
        }
        .interactiveDismissDisabled(true)  // Block dismissal to force focus
        .onAppear {
            print("StudySessionView onAppear")
            if !timerModel.isTimerRunning {
                timerModel.startTimer(for: 25 * 60)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                timerModel.updateTimeRemaining()
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

struct StudySessionView_Previews: PreviewProvider {
    static var previews: some View {
        StudySessionView()
            .environmentObject(StudyTimerModel(xpModel: XPModel(), miningModel: MiningModel()))
    }
}
