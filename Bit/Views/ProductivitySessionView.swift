import SwiftUI

struct ProductivitySessionView: View {
    @State private var sessionDuration: TimeInterval = 25 * 60 // Default 25 minutes (Pomodoro)
    @State private var engagement: Float = 0.8
    @State private var taskType: String = "Reading"
    @State private var difficulty: Int = 3
    @State private var completionPercentage: Float = 1.0
    @State private var location: String = "Home"
    @State private var energyLevel: Int = 3
    @State private var isSessionActive = false
    @State private var sessionStartTime: Date?
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    
    let taskTypes = ["Reading", "Problem Solving", "Memorization", "Writing", "Research", "Practice"]
    let locations = ["Home", "Library", "School", "Coffee Shop", "Office", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Study Session")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Timer display
                if isSessionActive {
                    Text(timeFormatted(elapsedTime))
                        .font(.system(size: 60, weight: .bold))
                        .padding()
                    
                    Button(action: endSession) {
                        Text("End Session")
                            .font(.headline)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    // Session configuration
                    Group {
                        // Task Type
                        Picker("Task Type", selection: $taskType) {
                            ForEach(taskTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Difficulty
                        HStack {
                            Text("Difficulty:")
                            Spacer()
                            ForEach(1..<6) { i in
                                Button(action: { difficulty = i }) {
                                    Image(systemName: i <= difficulty ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        // Location
                        Picker("Location", selection: $location) {
                            ForEach(locations, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Energy Level
                        HStack {
                            Text("Energy Level:")
                            Spacer()
                            ForEach(1..<6) { i in
                                Button(action: { energyLevel = i }) {
                                    Image(systemName: i <= energyLevel ? "battery.100" : "battery.0")
                                        .foregroundColor(i <= energyLevel ? .green : .gray)
                                }
                            }
                        }
                        
                        // Session Duration
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Picker("", selection: $sessionDuration) {
                                Text("15 min").tag(15 * 60.0)
                                Text("25 min").tag(25 * 60.0)
                                Text("45 min").tag(45 * 60.0)
                                Text("60 min").tag(60 * 60.0)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 200)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Start button
                    Button(action: startSession) {
                        Text("Start Session")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Data export button
                Button(action: exportData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Training Data")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding(.top, 30)
            }
            .padding()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startSession() {
        sessionStartTime = Date()
        isSessionActive = true
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            
            // Automatically end session when target duration is reached
            if elapsedTime >= sessionDuration {
                endSession()
            }
        }
    }
    
    private func endSession() {
        timer?.invalidate()
        timer = nil
        isSessionActive = false
        
        guard let startTime = sessionStartTime else { return }
        let actualDuration = Date().timeIntervalSince(startTime)
        
        // Record the session in ProductivityTracker
        ProductivityTracker.shared.recordProductiveSession(
            duration: actualDuration,
            engagement: engagement,
            taskType: taskType,
            difficulty: difficulty,
            completionPercentage: completionPercentage,
            location: location,
            userEnergyLevel: energyLevel
        )
        
        // Reset start time
        sessionStartTime = nil
    }
    
    private func exportData() {
        if let url = ProductivityTracker.shared.exportTrainingData() {
            // Show success message
            print("Data exported to: \(url)")
            
            #if os(iOS)
            // Share the file
            let activityController = UIActivityViewController(
                activityItems: [url], 
                applicationActivities: nil
            )
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityController, animated: true)
            }
            #endif
        }
    }
    
    private func timeFormatted(_ totalSeconds: TimeInterval) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
