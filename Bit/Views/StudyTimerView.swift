import SwiftUI

struct StudyTimerView: View {
    @EnvironmentObject var timerModel: StudyTimerModel
    @EnvironmentObject var miningModel: MiningModel
    @EnvironmentObject var categoriesVM: CategoriesViewModel
    @Environment(\.scenePhase) var scenePhase

    @State private var isShowingCategorySheet = false
    @State private var showSessionEndedPopup = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                        isShowingCategorySheet = true
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
                    }) {
                        Text("Add 25 Min")
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
            .onAppear {
                if categoriesVM.selectedTopic == nil {
                    categoriesVM.selectedTopic = categoriesVM.loadSelectedTopic()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    timerModel.updateTimeRemaining()
                }
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

            .sheet(isPresented: $isShowingCategorySheet) {
                CategorySelectionSheet(
                    categories: categoriesVM.categories,
                    selected: $categoriesVM.selectedTopic, // Use the binding to the view model's selectedTopic
                    isPresented: $isShowingCategorySheet,
                    onAddCategory: { name in
                        categoriesVM.addCategory(name: name)
                        categoriesVM.selectedTopic = categoriesVM.categories.last // Automatically select the newly added category
                    },
                    onDeleteCategory: { category in
                        categoriesVM.deleteCategory(category)
                        if categoriesVM.selectedTopic?.id == category.id {
                            categoriesVM.selectedTopic = nil // Clear the selection if the selected category is deleted
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showSessionEndedPopup) {
            VStack(spacing: 20) {
                Text("⏰ Time's Up!")
                    .font(.largeTitle)
                    .bold()
                Text("You studied for \(timerModel.studiedMinutes) minutes.")
                    .multilineTextAlignment(.center)
                Button("Awesome!") {
                    showSessionEndedPopup = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
        }
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
