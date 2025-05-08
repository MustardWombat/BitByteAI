import SwiftUI

struct StreakDisplay: View {
    @EnvironmentObject var timerModel: StudyTimerModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(timerModel.dailyStreak)")
                .font(.headline)
                .foregroundColor(.orange)
        }
    }
}
