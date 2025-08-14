import Foundation
import Combine
import SwiftUI
import CloudKit

#if os(iOS)
import UIKit
import ActivityKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// Use a proper typealias approach for cross-platform activity
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
typealias TimerActivity = Activity<StudyTimerAttributes>?
#else
typealias TimerActivity = Any?
#endif

struct StudyTimerState: Codable {
    let earnedRewards: [String]
    let totalTimeStudied: Int
    let focusStreak: Int
    let selectedTopic: Category?  // Persist selected topic
    let dailyStreak: Int
    let lastStudyDate: Date?
    let weeklyStudyMinutes: Int // Add weekly study minutes tracking
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
    @Published var userEnergyLevel: Int? = nil
    @Published var showBreakPrompt: Bool = false // Added missing property
    @Published var weeklyStudyMinutes: Int = 0 {
        didSet { saveData() }
    }
    @Published var isRocketOverlayActive: Bool = false   // New shared rocket overlay flag
    
    // Track the user's focus level
    private var focusCheckCount: Int = 0
    private var totalFocusScore: Float = 0
    
    var focusScore: Float {
        return focusCheckCount > 0 ? totalFocusScore / Float(focusCheckCount) : 0.7 // Default to 0.7 if no checks
    }
    
    var categoryName: String? {
        return selectedTopic?.name
    }
    
    var taskDifficulty: Int? {
        // Add a safe way to get difficulty since Category doesn't have this property
        return 3 // Default medium difficulty
        // When you add difficulty to Category model, change to: return selectedTopic?.difficulty
    }
    
    // Persistence key
    private let studyDataKey = "StudyTimerModelData"
    private let weeklyDataKey = "WeeklyStudyData"
    private let weekStartDateKey = "WeekStartDate"
    
    var xpModel: XPModel?
    var miningModel: MiningModel?
    var categoriesVM: CategoriesViewModel?
    
    private var timer: Timer?
    private var timerStartDate: Date?
    var timerStartDatePublic: Date? { timerStartDate }
    private var initialDuration: Int = 0
    var initialDurationPublic: Int { initialDuration }
    private var initialEndDate: Date? // Fixed end date
    var timerEndDatePublic: Date? {
        guard let start = timerStartDate else { return nil }
        return start.addingTimeInterval(TimeInterval(initialDuration))
    }
    
    #if os(iOS)
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    #endif
    
    // Use the typealias
    private var liveActivity: TimerActivity = nil
    
    init(xpModel: XPModel? = nil, miningModel: MiningModel? = nil, categoriesVM: CategoriesViewModel? = nil) {
        self.xpModel = xpModel
        self.miningModel = miningModel
        self.categoriesVM = categoriesVM
        loadData()
        checkAndResetWeeklyData()
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
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
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
            // Award planet rewards
            calculateReward(using: studiedTimeSeconds)
            
            // Award coin rewards based on study time
            let coinReward = RewardCalculator.calculateCoinReward(using: studiedTimeSeconds)
            print("Awarding \(coinReward) coins for studying \(studiedTimeMinutes) minutes")
            
            // Use notification pattern to deposit coins - more decoupled approach
            NotificationCenter.default.post(
                name: Notification.Name("DepositCoins"),
                object: nil,
                userInfo: ["amount": coinReward]
            )
            
            // Update weekly study minutes
            updateWeeklyStudyMinutes(minutes: studiedTimeMinutes)
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
    
    func endTimer(wasSuccessful: Bool = true) {
        // Calculate how long the session lasted
        let sessionDuration = initialDuration - timeRemaining
        
        // Only record successful sessions that were reasonably long (at least 1 minute)
        if wasSuccessful && sessionDuration > 60 {
            // Record this productive session
            let session = ProductivityTracker.ProductivitySession(
                timestamp: Date(),
                duration: TimeInterval(sessionDuration),
                dayOfWeek: Calendar.current.component(.weekday, from: Date()),
                engagement: focusScore, // Use the focus score if you have one
                taskType: selectedTopic?.name ?? "Unknown",
                difficulty: taskDifficulty,
                completionPercentage: 1.0, // Assuming 100% completion for now
                userEnergyLevel: nil // Could add a user energy prompt later
            )
            
            ProductivityTracker.shared.addSession(session)
        }
        
        // Existing end timer code
        isTimerRunning = false
        stopTimer()
        showBreakPrompt = true
    }
    
    func calculateReward(using seconds: Int) {
        totalTimeStudied += seconds
        let planetType = RewardCalculator.calculateReward(using: seconds, miningModel: miningModel)
        
        reward = planetType.rawValue
        earnedRewards.append(planetType.rawValue)
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
    
    func recordFocusLevel(_ level: Float) {
        totalFocusScore += level
        focusCheckCount += 1
    }
    
    private func saveData() {
        let state = StudyTimerState(
            earnedRewards: earnedRewards,
            totalTimeStudied: totalTimeStudied,
            focusStreak: focusStreak,
            selectedTopic: selectedTopic,
            dailyStreak: dailyStreak,
            lastStudyDate: lastStudyDate,
            weeklyStudyMinutes: weeklyStudyMinutes  // Add this
        )
        if let data = try? JSONEncoder().encode(state) {
            NSUbiquitousKeyValueStore.default.set(data, forKey: studyDataKey)
            print("DEBUG: Saved StudyTimerState with topic: \(selectedTopic?.name ?? "nil") to iCloud")
        } else {
            print("❌ Failed to encode StudyTimerState")
        }
    }
    
    internal func loadData() {
        if let cloudData = NSUbiquitousKeyValueStore.default.data(forKey: studyDataKey),
           let state = try? JSONDecoder().decode(StudyTimerState.self, from: cloudData) {
            earnedRewards = state.earnedRewards
            totalTimeStudied = state.totalTimeStudied
            focusStreak = state.focusStreak
            selectedTopic = state.selectedTopic
            dailyStreak = state.dailyStreak
            lastStudyDate = state.lastStudyDate
            weeklyStudyMinutes = state.weeklyStudyMinutes  // Add this
        } else if let localData = UserDefaults.standard.data(forKey: studyDataKey),
                  let state = try? JSONDecoder().decode(StudyTimerState.self, from: localData) {
            earnedRewards = state.earnedRewards
            totalTimeStudied = state.totalTimeStudied
            focusStreak = state.focusStreak
            selectedTopic = state.selectedTopic
            dailyStreak = state.dailyStreak
            lastStudyDate = state.lastStudyDate
            weeklyStudyMinutes = state.weeklyStudyMinutes  // Add this
        }
    }
    
    private func checkAndResetWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return
        }
        
        // Get the saved week start date
        if let savedWeekStartDate = UserDefaults.standard.object(forKey: weekStartDateKey) as? Date {
            // If we're in a new week, reset weekly study minutes
            if !calendar.isDate(savedWeekStartDate, inSameDayAs: currentWeekStart) {
                weeklyStudyMinutes = 0
                UserDefaults.standard.set(currentWeekStart, forKey: weekStartDateKey)
                saveData()
            }
        } else {
            // If no start date is saved, save the current week's start date
            UserDefaults.standard.set(currentWeekStart, forKey: weekStartDateKey)
        }
    }
    
    private func updateWeeklyStudyMinutes(minutes: Int) {
        weeklyStudyMinutes += minutes
        saveData()
        
        // Sync to CloudKit
        syncWeeklyStudyDataToCloudKit(minutes: weeklyStudyMinutes)
    }
    
    private func syncWeeklyStudyDataToCloudKit(minutes: Int) {
        guard minutes > 0 else { return }
        
        // Get or create UserID
        let defaultID = UUID().uuidString
        #if os(iOS)
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? defaultID
        #else
        let deviceID = "mac-user-\(UUID().uuidString)"
        #endif
        
        let userID = UserDefaults.standard.string(forKey: "UserID") ?? deviceID
        
        // Save userID if not already saved
        if UserDefaults.standard.string(forKey: "UserID") == nil {
            UserDefaults.standard.set(userID, forKey: "UserID")
        }
        
        // Get the current week's start date
        let calendar = Calendar.current
        guard let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return
        }
        
        // Get username or use device name
        #if os(iOS)
        let deviceName = UIDevice.current.name
        #else
        let deviceName = Host.current().localizedName ?? "Mac User"
        #endif
        
        // Removed line:
        // let username = UserDefaults.standard.string(forKey: "Username") ?? deviceName
        
        // Create record ID with a deterministic key to avoid duplicates
        let weekString = DateFormatter.localizedString(from: weekStartDate, dateStyle: .short, timeStyle: .none)
        let recordID = CKRecord.ID(recordName: "\(userID)-\(weekString)")
        let record = CKRecord(recordType: "weekly_Study_Data", recordID: recordID)
        
        // Use exact field names from CloudKit schema
        record["userID"] = userID as CKRecordValue
        record["weekStartDate"] = weekStartDate as CKRecordValue
        record["totalMinutes"] = minutes as CKRecordValue
        
        // Create a proper daily_Minutes array (required field)
        let today = Calendar.current.component(.weekday, from: Date()) - 1 // 0-based index (0 = Sunday)
        var dailyMinutes = [0, 0, 0, 0, 0, 0, 0] // Initialize with zeros for each day
        dailyMinutes[today] = minutes // Put all minutes on today
        record["daily_Minutes"] = dailyMinutes as CKRecordValue
        
        print("DEBUG: Saving record with fields: userID=\(userID), totalMinutes=\(minutes), daily_Minutes=\(dailyMinutes)")
        
        // Save to CloudKit public database - use the correct container
        let bundleID = Bundle.main.bundleIdentifier ?? "com.jameswilliams.Bit"
        let containerID = "iCloud.\(bundleID)"
        let container = CKContainer(identifier: containerID)
        let publicDB = container.publicCloudDatabase
        
        publicDB.save(record) { (savedRecord, error) in
            if let error = error {
                print("Error saving weekly study data to CloudKit: \(error.localizedDescription)")
            } else {
                print("Successfully saved weekly study data to CloudKit: \(minutes) minutes")
            }
        }
    }
    
    private func startLiveActivity(duration: Int, topic: String) {
        #if os(iOS)
        guard let endDate = initialEndDate else { return }
        let attributes = StudyTimerAttributes(topic: topic)
        let state = StudyTimerAttributes.ContentState(
            timeRemaining: duration,
            endDate: endDate
        )
        let content = ActivityContent(state: state, staleDate: nil)
        do {
            liveActivity = try Activity<StudyTimerAttributes>.request(
                attributes: attributes,
                content: content
            )
        } catch {
            print("Failed to start live activity: \(error)")
        }
        #endif
    }
    
    private func updateLiveActivity(remaining: Int) {
        #if os(iOS)
        guard let activity = liveActivity, let endDate = initialEndDate else { return }
        Task {
            await activity.update(ActivityContent(state: StudyTimerAttributes.ContentState(
                timeRemaining: remaining,
                endDate: endDate
            ), staleDate: nil))
        }
        #else
        // No live activity update on macOS.
        #endif
    }
    
    private func stopLiveActivity() {
        #if os(iOS)
        guard let activity = liveActivity else { return }
        Task {
            let finalContent = ActivityContent(state: StudyTimerAttributes.ContentState(
                timeRemaining: 0,
                endDate: initialEndDate ?? Date()
            ), staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
            liveActivity = nil
        }
        #else
        // Nothing to stop on macOS.
        #endif
    }
    
    private func endBackgroundTask() {
        #if os(iOS)
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
        #endif
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

