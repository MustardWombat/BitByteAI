import Foundation
import Combine
import SwiftUI
import ActivityKit

#if os(iOS)
import UIKit
#endif

struct StudyTimerState: Codable {
    let earnedRewards: [String]
    let totalTimeStudied: Int
    let focusStreak: Int
    let selectedTopic: Category?  // Persist selected topic
    let dailyStreak: Int
    let lastStudyDate: Date?
}

class StudyTimerModel: ObservableObject {
    @Published var earnedRewards: [String] = [] {
        didSet { saveData() }
    }
    @Published var timeRemaining: Int = 0
    @Published var isTimerRunning: Bool = false
    @Published var totalTimeStudied: Int = 0 {
        didSet { saveData() }
    }
    @Published var reward: String? = nil
    @Published var isFocusCheckActive: Bool = false
    @Published var focusStreak: Int = 0 {
        didSet { saveData() }
    }
    @Published var selectedTopic: Category? {
        didSet {
            print("DEBUG: selectedTopic changed to: \(selectedTopic?.name ?? "nil")")
            saveData()
        }
    }
    @Published var dailyStreak: Int = 0 {
        didSet { saveData() }
    }
    @Published var lastStudyDate: Date? = nil {
        didSet { saveData() }
    }
    
    // Persistence key
    private let studyDataKey = "StudyTimerModelData"
    
    var xpModel: XPModel?
    var miningModel: MiningModel?
    var categoriesVM: CategoriesViewModel?
    
    private var timer: Timer?
    private var timerStartDate: Date?
    private var initialDuration: Int = 0
    private var initialEndDate: Date? // Fixed end date
    
    #if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif
    
    private var liveActivity: Activity<StudyTimerAttributes>? = nil
    
    init(xpModel: XPModel? = nil, miningModel: MiningModel? = nil, categoriesVM: CategoriesViewModel? = nil) {
        self.xpModel = xpModel
        self.miningModel = miningModel
        self.categoriesVM = categoriesVM
        loadData()
        // Attempt to load the selected topic from CategoriesViewModel if not already loaded.
        if selectedTopic == nil, let cat = categoriesVM?.loadSelectedTopic() {
            selectedTopic = cat
        }
        // If still nil, set a default from categories (if available)
        if selectedTopic == nil, let firstCat = categoriesVM?.categories.first {
            selectedTopic = firstCat
            categoriesVM?.saveSelectedTopicID(firstCat.id)
        }
        print("DEBUG: Loaded selectedTopic: \(selectedTopic?.name ?? "nil")")
    }
    
    func startTimer(for duration: Int) {
        let maxDuration = 3600
        if isTimerRunning { return }
        
        initialDuration = min(duration, maxDuration)
        timerStartDate = Date()
        timeRemaining = initialDuration
        isTimerRunning = true
        reward = nil
        
        #if os(iOS)
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "StudyTimer") {
            self.endBackgroundTask()
        }
        #endif
        
        // Set fixed end date once.
        initialEndDate = Date().addingTimeInterval(TimeInterval(initialDuration))
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimeRemaining()
        }
        // Use "Focus" if a topic isn’t set; otherwise use selected topic.
        if let topic = selectedTopic {
            startLiveActivity(duration: initialDuration, topic: topic.name)
        } else {
            print("DEBUG: No topic selected. Using default 'Focus'")
            startLiveActivity(duration: initialDuration, topic: "Focus")
        }
    }
    
    func updateTimeRemaining() {
        guard let start = timerStartDate else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let newRemaining = max(0, initialDuration - elapsed)
        DispatchQueue.main.async { self.timeRemaining = newRemaining }
        updateLiveActivity(remaining: newRemaining)
        if newRemaining <= 0 { stopTimer() }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        let studiedTimeSeconds = Int(Date().timeIntervalSince(timerStartDate ?? Date()))
        let studiedTimeMinutes = studiedTimeSeconds / 60
        
        print("Adding \(studiedTimeSeconds) sec (\(studiedTimeMinutes) min) XP")
        xpModel?.addXP(studiedTimeSeconds)
        
        if studiedTimeSeconds >= 300 {
            calculateReward(using: studiedTimeSeconds)
        }
        
        if let topic = selectedTopic, let vm = categoriesVM {
            vm.logStudyTime(categoryID: topic.id, date: Date(), minutes: studiedTimeMinutes)
        }
        
        // --- Daily Streak Logic ---
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = lastStudyDate {
            let last = Calendar.current.startOfDay(for: lastDate)
            let diff = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
            if diff == 1 {
                dailyStreak += 1
            } else if diff > 1 {
                dailyStreak = 1
            } // else diff == 0, same day, don't increment
        } else {
            dailyStreak = 1
        }
        lastStudyDate = today
        // --- End Daily Streak Logic ---
        
        stopLiveActivity()
        endBackgroundTask()
        timerStartDate = nil
    }
    
    func calculateReward(using seconds: Int) {
        totalTimeStudied += seconds
        var planetType: PlanetType
        if seconds >= 1800 {
            planetType = .rare
        } else if seconds >= 900 {
            planetType = .common
        } else {
            planetType = .tiny
        }
        
        reward = planetType.rawValue
        earnedRewards.append(planetType.rawValue)
        
        if let planet = miningModel?.getPlanet(ofType: planetType) {
            miningModel?.availablePlanets.append(planet)
            print("Added planet: \(planet.name)")
        }
    }
    
    func harvestRewards() -> Int {
        let rewardValue = earnedRewards.reduce(0) { total, reward in
            switch reward {
            case PlanetType.rare.rawValue: return total + 50
            case PlanetType.common.rawValue: return total + 20
            case PlanetType.tiny.rawValue: return total + 5
            default: return total
            }
        }
        earnedRewards.removeAll()
        return rewardValue
    }
    
    func triggerFocusCheck() {
        isFocusCheckActive = true
    }
    
    func handleFocusAnswer(yes: Bool) {
        if yes {
            focusStreak += 1
        } else {
            focusStreak = 0
            stopTimer()
        }
        isFocusCheckActive = false
    }
    
    private func saveData() {
        let state = StudyTimerState(
            earnedRewards: earnedRewards,
            totalTimeStudied: totalTimeStudied,
            focusStreak: focusStreak,
            selectedTopic: selectedTopic,
            dailyStreak: dailyStreak,
            lastStudyDate: lastStudyDate
        )
        if let data = try? JSONEncoder().encode(state) {
            NSUbiquitousKeyValueStore.default.set(data, forKey: studyDataKey)
            print("DEBUG: Saved StudyTimerState with topic: \(selectedTopic?.name ?? "nil") to iCloud")
        } else {
            print("❌ Failed to encode StudyTimerState")
        }
    }
    
    private func loadData() {
        if let data = NSUbiquitousKeyValueStore.default.data(forKey: studyDataKey),
           let state = try? JSONDecoder().decode(StudyTimerState.self, from: data) {
            earnedRewards = state.earnedRewards
            totalTimeStudied = state.totalTimeStudied
            focusStreak = state.focusStreak
            selectedTopic = state.selectedTopic
            dailyStreak = state.dailyStreak
            lastStudyDate = state.lastStudyDate
            print("DEBUG: Loaded StudyTimerState with topic: \(selectedTopic?.name ?? "nil") from iCloud")
        }
    }

    func synchronizeICloud() {
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    #if os(iOS)
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    #else
    private func endBackgroundTask() {}
    #endif
    
    private func startLiveActivity(duration: Int, topic: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities not authorized")
            return
        }
        guard let endDate = initialEndDate else { return }
        let attributes = StudyTimerAttributes(topic: topic)
        let state = StudyTimerAttributes.ContentState(timeRemaining: duration, endDate: endDate)
        do {
            liveActivity = try Activity<StudyTimerAttributes>.request(attributes: attributes, contentState: state)
            print("✅ Live Activity started with topic: \(topic)")
        } catch {
            print("❌ Failed to start live activity: \(error)")
        }
    }
    
    private func updateLiveActivity(remaining: Int) {
        guard let activity = liveActivity, let endDate = initialEndDate else { return }
        Task {
            await activity.update(using: StudyTimerAttributes.ContentState(
                timeRemaining: remaining,
                endDate: endDate
            ))
        }
    }
    
    private func stopLiveActivity() {
        guard let activity = liveActivity else { return }
        Task {
            await activity.end(dismissalPolicy: .immediate)
            liveActivity = nil
        }
    }
}

extension StudyTimerModel {
    var studiedMinutes: Int {
        if let start = timerStartDate {
            return Int(Date().timeIntervalSince(start)) / 60
        }
        return 0
    }
}

