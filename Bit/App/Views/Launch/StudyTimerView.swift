import SwiftUI

struct StudyTimerView: View {
    @EnvironmentObject var timerModel: StudyTimerModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var miningModel: MiningModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @Environment(\.scenePhase) var scenePhase

    @State private var rocketShouldAnimate = false
    @State private var isShowingCategorySheet = false
    @State private var showSessionEndedPopup = false
    @State private var isShowingEditGoalView = false
    @State private var isLaunching = false   // new: control launch animation
    @State private var showRocketOverlay = false   // new: control overlay appearance
    @State private var showLandButton = false   // new: control land button appearance
    @State private var isStudying: Bool = false

    @State private var rocketVibration: CGSize = .zero
    @State private var vibrationTimer: Timer? = nil

    private func handleSessionEnded() {
        isStudying = false
        showSessionEndedPopup = true
    }

    var body: some View {
        ZStack {
            // Main content wrapped with disabled modifier to lock interactions during focus mode
            VStack(spacing: 20) {
                // Fixed header: timer + rocket
                VStack(alignment: .leading, spacing: 10) {
                    // MARK: - Timer display
                    Text(formatTime(timerModel.timeRemaining))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(timerModel.isTimerRunning ? .green : .red)
                        .animation(nil, value: timerModel.timeRemaining)  // ← disable any animation on timer updates
                        .frame(maxWidth: .infinity, alignment: .center)  // center horizontally

                    RocketSprite(animate: $rocketShouldAnimate, isStudying: $isStudying)
                        .frame(width: 192, height: 192)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .offset(x: rocketVibration.width, y: rocketVibration.height)
                }
                .padding(.top, 100)
                .padding(.horizontal, 20)

                // Now the rest of the UI falls off together
                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Reward display
                    if let reward = timerModel.reward {
                        Text("You earned: \(reward)")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }

                    // MARK: - Topic Selector
                    Text("Selected Topic:")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button(action: {
                        withAnimation(.spring()) { // Trigger animation when button is pressed
                            isShowingCategorySheet = true
                        }
                    }) {
                        HStack {
                            if let topic = categoriesVM.selectedTopic {
                                Circle()
                                    .fill(topic.displayColor)
                                    .frame(width: 12, height: 12)
                                Text(topic.name)
                                    .foregroundColor(.white)
                            } else {
                                Text("Choose a topic")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.up")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }

                    // MARK: - Control buttons
                    HStack {
                        Button(action: {
                            rocketShouldAnimate = true
                            timerModel.selectedTopic = categoriesVM.selectedTopic
                            timerModel.categoriesVM = categoriesVM
                            timerModel.xpModel = xpModel
                            timerModel.startTimer(for: 25 * 60)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.84) {
                                isStudying = true
                            }
                            withAnimation(.easeInOut(duration: 1)) {
                                isLaunching = true
                                timerModel.isRocketOverlayActive = true    // ← trigger shell animation
                            }
                            // delay the full-screen overlay to let the animation finish
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showRocketOverlay = true
                            }
                            // Notify the shell to wipe off screen
                            NotificationCenter.default.post(name: .wipeShell, object: nil)
                            // schedule land button
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation { showLandButton = true }
                            }
                        }) {
                            Text("Launch")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(categoriesVM.selectedTopic == nil ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(categoriesVM.selectedTopic == nil) // Disable if no topic is selected
                    }
                    .padding()

                    Spacer()
                }
                .offset(y: isLaunching
                         ? UIScreen.main.bounds.height
                         : 0)
                .animation(.easeInOut(duration: 1), value: isLaunching)
            }
            .padding()
            .allowsHitTesting(!isLaunching)

            .onAppear {
                if categoriesVM.selectedTopic == nil {
                    categoriesVM.selectedTopic = categoriesVM.loadSelectedTopic()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                #if os(iOS) || os(macOS)
                if newPhase == .active {
                    timerModel.updateTimeRemaining()
                }
                #endif
            }
            .onChange(of: timerModel.reward) { newReward in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    timerModel.reward = nil
                }
            }
            .onChange(of: timerModel.timeRemaining) { newValue in
                if newValue == 0 && !timerModel.isTimerRunning {
                    handleSessionEnded()
                }
            }
            .onChange(of: isStudying) { studying in
                if studying {
                    vibrationTimer?.invalidate()
                    vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
                        rocketVibration = CGSize(width: CGFloat.random(in: -1.2...1.2), height: CGFloat.random(in: -1.2...1.2))
                    }
                } else {
                    vibrationTimer?.invalidate()
                    rocketVibration = .zero
                }
            }
            .onDisappear {
                vibrationTimer?.invalidate()
                vibrationTimer = nil
                rocketVibration = .zero
            }

            if isShowingEditGoalView {
                EditGoalView(
                    goalInput: String((categoriesVM.selectedTopic?.weeklyGoalMinutes ?? 60) / 60),
                    onSave: { newGoal in
                        if let hours = Int(newGoal), let topic = categoriesVM.selectedTopic {
                            categoriesVM.updateWeeklyGoal(for: topic, newGoalMinutes: hours * 60)
                        }
                        isShowingEditGoalView = false
                    },
                    onCancel: {
                        isShowingEditGoalView = false
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                )) // Apply consistent animation
                .zIndex(3)
            }


            // Land button appears 5s after launch
            if showLandButton {
                Button("Land") {
                    isStudying = false
                    timerModel.stopTimer()  // stop the running timer
                    NotificationCenter.default.post(name: .restoreShell, object: nil)  // restore shell UI
                    handleSessionEnded()
                    withAnimation {
                        isLaunching = false
                        timerModel.isRocketOverlayActive = false
                        showRocketOverlay = false
                        showLandButton = false
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 216)
                .transition(.opacity)
                .zIndex(10)
            }

            // Fullscreen takeover overlay (delayed)
            // overlay removed to prevent black full-screen takeover
        }
        .fullScreenCover(isPresented: $isShowingCategorySheet) {
            CategorySelectionOverlay(
                categories: $categoriesVM.categories,
                selected: $categoriesVM.selectedTopic,
                isPresented: $isShowingCategorySheet
            )
        }
        .fullScreenCover(isPresented: $showSessionEndedPopup) {
            let elapsedSeconds: Int = {
                if let start = timerModel.timerStartDatePublic, let end = timerModel.timerEndDatePublic {
                    return min(Int(end.timeIntervalSince(start)), timerModel.initialDurationPublic)
                } else if let start = timerModel.timerStartDatePublic {
                    // If timerEndDate is not available, use now
                    return min(Int(Date().timeIntervalSince(start)), timerModel.initialDurationPublic)
                } else {
                    return timerModel.initialDurationPublic - timerModel.timeRemaining
                }
            }()
            let studiedMinutes = elapsedSeconds / 60
            let studiedSeconds = elapsedSeconds % 60
            let xpEarned = elapsedSeconds
            let coinsEarned = RewardCalculator.calculateCoinReward(using: elapsedSeconds)
            SessionEndedOverlay(
                studiedMinutes: studiedMinutes,
                studiedSeconds: studiedSeconds,
                xpEarned: xpEarned,
                coinsEarned: coinsEarned,
                onDismiss: {
                    showSessionEndedPopup = false
                }
            )
        }
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Custom view for editing the study goal
struct EditGoalView: View {
    @State var goalInput: String
    var onSave: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Study Goal (hours per week)")
                .font(.headline)
            TextField("Enter goal in hours", text: $goalInput)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Save") {
                    onSave(goalInput)
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                Button("Cancel") {
                    onCancel()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
}

// Custom overlay for category selection

