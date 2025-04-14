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
            StarOverlay()
            VStack(spacing: 20) {
                // MARK: - Topic Selector Sheet Trigger
                VStack(alignment: .leading, spacing: 10) {
                    Text("Selected Topic:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        isShowingCategorySheet = true
                    }) {
                        HStack {
                            if let topic = timerModel.selectedTopic {
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
                
                // MARK: - Control buttons
                HStack {
                    Button(action: {
                        // Use the timerModel's selectedTopic directly.
                        timerModel.startTimer(for: 25 * 60)
                    }) {
                        Text("Add 25 Min")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
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
                // Initialize timerModel.selectedTopic if it’s nil.
                if timerModel.selectedTopic == nil {
                    timerModel.selectedTopic = categoriesVM.loadSelectedTopic() ?? categoriesVM.categories.first
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    timerModel.updateTimeRemaining()
                }
            }
            .onChange(of: timerModel.reward) { _ in
                // Clear reward after a short delay.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    timerModel.reward = nil
                }
            }
            .onChange(of: timerModel.timeRemaining) { newValue in
                if newValue == 0 && !timerModel.isTimerRunning {
                    // Calculate studied minutes (this example uses the studiedMinutes computed property)
                    let minutesStudied = timerModel.studiedMinutes
                    
                    // If a topic is selected, update its logs.
                    if let topic = timerModel.selectedTopic {
                        // Call the logStudyTime function in your CategoriesViewModel.
                        categoriesVM.logStudyTime(categoryID: topic.id, date: Date(), minutes: minutesStudied)
                    }
                    
                    // Show the session ended popup.
                    showSessionEndedPopup = true
                }
            }
            .sheet(isPresented: $isShowingCategorySheet) {
                CategorySelectionSheet(
                    categories: categoriesVM.categories,
                    selected: $timerModel.selectedTopic,
                    isPresented: $isShowingCategorySheet,
                    onCategorySelected: { category in
                        // Persist selection and update the timer model.
                        categoriesVM.saveSelectedTopicID(category.id)
                        timerModel.selectedTopic = category
                    },
                    onAddCategory: { name in
                        categoriesVM.addCategory(name: name)
                        // Automatically select newly added category.
                        timerModel.selectedTopic = categoriesVM.categories.last
                    },
                    onDeleteCategory: { category in
                        categoriesVM.deleteCategory(category)
                        // If the deleted category was selected, clear the selection.
                        if timerModel.selectedTopic?.id == category.id {
                            timerModel.selectedTopic = nil
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
