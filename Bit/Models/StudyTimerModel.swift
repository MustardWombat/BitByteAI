import Foundation
import Combine
import SwiftUI
import ActivityKit

#if os(iOS)
import UIKit
#endif

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

    var xpModel: XPModel?
    var miningModel: MiningModel?
    var selectedTopic: Category?
    var categoriesVM: CategoriesViewModel?

    private var timer: Timer?
    private var timerStartDate: Date?
    private var initialDuration: Int = 0
    private let studyDataKey = "StudyTimerModelData"
    private var initialEndDate: Date? // New property for a fixed end date

    #if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif

    private var liveActivity: Activity<StudyTimerAttributes>? = nil

    init(xpModel: XPModel? = nil, miningModel: MiningModel? = nil) {
        self.xpModel = xpModel
        self.miningModel = miningModel
        loadData()
    }

    func startTimer(for duration: Int) {
        let maxDuration = 3600

        if isTimerRunning {
            // Optional: Disable stacking
            return
        } else {
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

            // Set the fixed end date once
            initialEndDate = Date().addingTimeInterval(TimeInterval(initialDuration))
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.updateTimeRemaining()
            }

            startLiveActivity(duration: initialDuration, topic: "Focus")
        }
    }

    func updateTimeRemaining() {
        guard let start = timerStartDate else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let newRemaining = max(0, initialDuration - elapsed)
        DispatchQueue.main.async { self.timeRemaining = newRemaining }
        updateLiveActivity(remaining: newRemaining)
        if newRemaining <= 0 {
            stopTimer()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false

        let studiedTimeSeconds = Int(Date().timeIntervalSince(timerStartDate ?? Date()))
        let studiedTimeMinutes = studiedTimeSeconds / 60

        print("Adding \(studiedTimeSeconds) seconds (\(studiedTimeMinutes) min) XP")
        xpModel?.addXP(studiedTimeSeconds)

        if studiedTimeSeconds >= 300 {
            calculateReward(using: studiedTimeSeconds)
        }

        if let topic = selectedTopic, let vm = categoriesVM {
            vm.logStudyTime(categoryID: topic.id, date: Date(), minutes: studiedTimeMinutes)
        }

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
            print("🪐 Added planet: \(planet.name)")
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
        let data: [String: Any] = [
            "earnedRewards": earnedRewards,
            "totalTimeStudied": totalTimeStudied,
            "focusStreak": focusStreak
        ]
        UserDefaults.standard.set(data, forKey: studyDataKey)
    }

    private func loadData() {
        if let data = UserDefaults.standard.dictionary(forKey: studyDataKey) {
            earnedRewards = data["earnedRewards"] as? [String] ?? []
            totalTimeStudied = data["totalTimeStudied"] as? Int ?? 0
            focusStreak = data["focusStreak"] as? Int ?? 0
        }
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
            print("✅ Live Activity started")
        } catch {
            print("❌ Failed to start live activity: \(error)")
        }
    }

    private func updateLiveActivity(remaining: Int) {
        guard let activity = liveActivity, let endDate = initialEndDate else { return }
        Task {
            await activity.update(using: StudyTimerAttributes.ContentState(
                timeRemaining: remaining,
                endDate: endDate  // Use the fixed end date here
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
