import SwiftUI

struct StudyTimerView: View {
    @EnvironmentObject var timerModel: StudyTimerModel
    @EnvironmentObject var miningModel: MiningModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @Environment(\.scenePhase) var scenePhase

    @State private var isShowingCategorySheet = false
    @State private var showSessionEndedPopup = false
    @State private var isShowingEditGoalView = false // Replace Apple popup state
    @State private var isRocketOverlayActive = false   // New state flag for rocket overlay

    var body: some View {
        ZStack {
            // Main content wrapped with disabled modifier to lock interactions during focus mode
            VStack(spacing: 20) {
                // Add padding to the top of the assets
                VStack(alignment: .leading, spacing: 10) {
                    // MARK: - Timer display
                    Text(formatTime(timerModel.timeRemaining))
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(timerModel.isTimerRunning ? .green : .red)

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

                }
                .padding(.top, 100) // Added top padding for the assets
                .padding(.horizontal, 20)

                // MARK: - Control buttons
                HStack {
                    Button(action: {
                        timerModel.selectedTopic = categoriesVM.selectedTopic
                        timerModel.categoriesVM = categoriesVM
                        timerModel.startTimer(for: 25 * 60)
                        isRocketOverlayActive = true // Activate rocket overlay on launch
                    }) {
                        Text("Launch")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(categoriesVM.selectedTopic == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(categoriesVM.selectedTopic == nil) // Disable if no topic is selected

                    Button(action: {
                        timerModel.stopTimer()
                    }) {
                        Text("Land")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!timerModel.isTimerRunning)
                }
                .padding()

                Spacer()
            }
            .padding()
            .allowsHitTesting(!isRocketOverlayActive) // Disable hit testing when rocket overlay is active
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
                    showSessionEndedPopup = true
                }
            }

            // Rocket overlay: full-screen pop-up window that covers the shell and locks interactions.
            if isRocketOverlayActive {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all) // Set background to black
                    VStack {
                        // Draggable handle similar to the sign-in screen style
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: 40, height: 6)
                            .padding(.top, 16)
                        
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image(systemName: "rocket.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .scaleEffect(1.3)
                                .transition(.scale)
                            Text(formatTime(timerModel.timeRemaining))
                                .font(.system(size: 64, weight: .bold, design: .monospaced))
                                .foregroundColor(timerModel.isTimerRunning ? .green : .red)
                            Button(action: {
                                withAnimation(.spring()) {
                                    timerModel.stopTimer()
                                    isRocketOverlayActive = false
                                }
                            }) {
                                Text("Land")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.black) // Set inner overlay background to black
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.move(edge: .bottom))
                }
                .animation(.spring(), value: isRocketOverlayActive)
                .zIndex(1000000) // Ensure it covers the shell
                .allowsHitTesting(true) // Ensure the overlay intercepts all touches.
            }

            if isShowingCategorySheet {
                CategorySelectionOverlay(
                    categories: $categoriesVM.categories, // updated: pass binding instead of value
                    selected: $categoriesVM.selectedTopic,
                    isPresented: $isShowingCategorySheet
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                ))
                .zIndex(2)
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

            if showSessionEndedPopup {
                SessionEndedOverlay(
                    studiedMinutes: timerModel.studiedMinutes,
                    onDismiss: {
                        showSessionEndedPopup = false
                    }
                )
                .transition(.opacity)
                .zIndex(4)
            }
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
