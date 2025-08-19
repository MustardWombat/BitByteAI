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
    @State private var isStudying: Bool = false

    @State private var rocketVibration: CGSize = .zero
    @State private var vibrationTimer: Timer? = nil

    @State private var containerHeight: CGFloat = 0

    // Added states for minute picker
    @State private var showMinutePicker = false
    @State private var selectedMinuteValue = 25

    private func handleSessionEnded() {
        isStudying = false
        showSessionEndedPopup = true
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    // Fixed header: timer + rocket
                    VStack(alignment: .leading, spacing: 10) {
                        // MARK: - Timer display replaced with Button
                        Button {
                            selectedMinuteValue = timerModel.timeRemaining > 0 ? timerModel.timeRemaining / 60 : 25
                            showMinutePicker = true
                        } label: {
                            Text(formatTime(timerModel.timeRemaining))
                                .font(.system(size: 64, weight: .bold, design: .monospaced))
                                .foregroundColor(timerModel.isTimerRunning ? .green : .red)
                                .animation(nil, value: timerModel.timeRemaining)  // ← disable any animation on timer updates
                                .frame(maxWidth: .infinity, alignment: .center)  // center horizontally
                        }

                        Button {
                            rocketShouldAnimate = true
                            timerModel.selectedTopic = categoriesVM.selectedTopic
                            timerModel.categoriesVM = categoriesVM
                            timerModel.xpModel = xpModel
                            timerModel.startTimer(for: timerModel.timeRemaining > 0 ? timerModel.timeRemaining : 25 * 60)
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
                        } label: {
                            RocketSprite(animate: $rocketShouldAnimate, isStudying: $isStudying)
                                .frame(width: 192, height: 192)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .offset(x: rocketVibration.width, y: rocketVibration.height)
                                .offset(y: isLaunching ? -400 : 0) // Added offset for launch animation
                                .animation(.easeInOut(duration: 1.5), value: isLaunching) // Animate rocket lift-off
                        }
                        .buttonStyle(PlainButtonStyle())
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
                            // Launch button removed as per instructions
                        }
                        .padding()

                        Spacer()
                    }
                    .offset(y: isLaunching
                             ? containerHeight
                             : 0)
                    .animation(.easeInOut(duration: 1), value: isLaunching)
                }
                .padding()
                .allowsHitTesting(!isLaunching)
                .onAppear {
                    containerHeight = geometry.size.height
                    if categoriesVM.selectedTopic == nil {
                        categoriesVM.selectedTopic = categoriesVM.loadSelectedTopic()
                    }
                }
                // Use standard .onChange for geometry.size.height - the older syntax with initial parameter is deprecated.
                .onChange(of: geometry.size.height) { newHeight in
                    containerHeight = newHeight
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
            // Removed vibration logic from StudyTimerView since RocketFocusOverlay owns it

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

            // Removed Land button block

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
            let totalTimeStudied = String(format: "%02d:%02d", elapsedSeconds / 60, elapsedSeconds % 60)
            let xpEarned = elapsedSeconds
            let coinsEarned = RewardCalculator.calculateCoinReward(using: elapsedSeconds)
            SessionEndedOverlay(
                totalTimeStudied: totalTimeStudied,
                xpEarned: xpEarned,
                coinsEarned: coinsEarned,
                onDismiss: {
                    showSessionEndedPopup = false
                }
            )
        }
        // Added minute picker sheet
        .sheet(isPresented: $showMinutePicker) {
            VStack(spacing: 20) {
                Text("Set Study Time")
                    .font(.headline)
                Picker("Minutes", selection: $selectedMinuteValue) {
                    ForEach(1...60, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                HStack {
                    Button("Cancel") {
                        showMinutePicker = false
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Set") {
                        if !timerModel.isTimerRunning {
                            timerModel.timeRemaining = selectedMinuteValue * 60
                        }
                        showMinutePicker = false
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        // Added fullScreenCover for RocketFocusOverlay
        .fullScreenCover(isPresented: $showRocketOverlay) {
            RocketFocusOverlay(
                isPresented: $showRocketOverlay,
                rocketShouldAnimate: $rocketShouldAnimate,
                isStudying: $isStudying,
                timerModel: timerModel,
                onLand: {
                    isStudying = false
                    timerModel.stopTimer()
                    handleSessionEnded()
                    withAnimation {
                        isLaunching = false
                        timerModel.isRocketOverlayActive = false
                        showRocketOverlay = false
                    }
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

