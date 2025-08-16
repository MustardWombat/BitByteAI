import SwiftUI

struct RocketFocusOverlay: View {
    @Binding var isPresented: Bool
    @Binding var rocketShouldAnimate: Bool
    @Binding var isStudying: Bool
    @ObservedObject var timerModel: StudyTimerModel
    var onLand: () -> Void

    @State private var rocketVibration: CGSize = .zero
    @State private var vibrationTimer: Timer? = nil
    @State private var rocketScale: CGFloat = 3.0
    @State private var rocketYOffset: CGFloat = 420
    @State private var showOverlayContent: Bool = false
    @State private var backgroundOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(backgroundOpacity).ignoresSafeArea()
            VStack(spacing: 32) {
                RocketSprite(animate: $rocketShouldAnimate, isStudying: $isStudying)
                    .frame(width: 192, height: 192)
                    .scaleEffect(rocketScale)
                    .offset(y: rocketYOffset + rocketVibration.height)
                    .offset(x: rocketVibration.width)

                Group {
                    Text(formatTime(timerModel.timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(timerModel.isTimerRunning ? .green : .red)
                    Button("Land") {
                        isStudying = false
                        timerModel.stopTimer()
                        onLand()
                        isPresented = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .opacity(showOverlayContent ? 1 : 0)
                .animation(.easeInOut(duration: 1.6), value: showOverlayContent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            isStudying = false
            DispatchQueue.main.async {
                isStudying = true
            }
            withAnimation(.easeInOut(duration: 2.4)) {
                backgroundOpacity = 1
            }
            withAnimation(.easeInOut(duration: 2.2)) {
                rocketScale = 1.0
                rocketYOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                showOverlayContent = true
            }
            startVibration()
        }
        .onDisappear {
            stopVibration()
        }
    }

    private func startVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            rocketVibration = CGSize(width: CGFloat.random(in: -1.2...1.2), height: CGFloat.random(in: -1.2...1.2))
        }
    }
    private func stopVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        rocketVibration = .zero
    }
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
