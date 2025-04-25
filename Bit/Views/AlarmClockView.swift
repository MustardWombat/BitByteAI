import SwiftUI

struct AlarmClockView: View {
    @EnvironmentObject var timerModel: StudyTimerModel
    @Binding var showAlarmClockView: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Studying...")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                // Progress bar for time remaining
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .padding(.horizontal, 40)

                Text(formatTime(timerModel.timeRemaining))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(timerModel.isTimerRunning ? .green : .red)

                HStack(spacing: 20) {
                    Button(action: {
                        timerModel.resetTimer()
                    }) {
                        Text("Reset")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        timerModel.stopTimer()
                        showAlarmClockView = false
                    }) {
                        Text("Land")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }

    var progress: Double {
        guard let totalTime = timerModel.totalTime, totalTime > 0 else { return 0 }
        return Double(totalTime - timerModel.timeRemaining) / Double(totalTime)
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
