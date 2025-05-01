import Foundation
import CoreML
import SwiftUI  // Added SwiftUI for @AppStorage
import Combine  // Add for ObservableObject

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Placeholder for the ML model until properly implemented
class NotificationTimePredictor {
    func prediction(input: [String: Any]) throws -> NotificationTimePrediction {
        // This is a simple placeholder that just returns default values
        return NotificationTimePrediction()
    }
}

// Placeholder for prediction results
struct NotificationTimePrediction {
    let optimalHour1: Int = 9
    let optimalMinute1: Int = 0
    let optimalHour2: Int = 17
    let optimalMinute2: Int = 0
}

// Make the class observable for SwiftUI
class ProductivityTracker: ObservableObject {
    static let shared = ProductivityTracker()
    
    // Store timestamps and additional context of productive sessions
    @AppStorage("productivitySessions") private var sessionsData: Data = Data()
    // Make this public so MLManager can access the count
    var productivitySessions: [ProductivitySession] = []
    
    // User preferences - make it published for SwiftUI bindings
    @Published var dataShareOptIn: Bool = false {
        didSet {
            // Persist to UserDefaults when changed
            UserDefaults.standard.set(dataShareOptIn, forKey: "dataShareOptIn")
        }
    }
    @AppStorage("lastDataShareDate") private var lastDataShareDate: Double = 0
    
    // Configuration
    private let maxStoredSessions = 100
    private let minSessionsForAnalysis = 10
    let minSessionsForAI = 20   // Changed from private to internal
    private let dataShareInterval: TimeInterval = 7 * 24 * 60 * 60 // One week
    
    private var aiModel: NotificationTimePredictor?
    private var mlModelURL: URL?
    
    struct ProductivitySession: Codable {
        let timestamp: Date
        let duration: TimeInterval
        let dayOfWeek: Int
        let engagement: Float // 0.0-1.0 representing user engagement level
        
        // New fields to enhance ML capabilities
        let taskType: String? // e.g., "reading", "problem-solving", "memorization"
        let difficulty: Int? // 1-5 scale
        let completionPercentage: Float? // 0.0-1.0
        let userEnergyLevel: Int? // 1-5 scale
        
        // Computed properties for ML features
        var hour: Int {
            return Calendar.current.component(.hour, from: timestamp)
        }
        
        var isWeekend: Bool {
            let weekday = Calendar.current.component(.weekday, from: timestamp)
            return weekday == 1 || weekday == 7 // Sunday or Saturday
        }
    }
    
    // Storage for sessions
    private var sessions: [ProductivitySession] = []
    
    // Method to get all recorded productivity sessions
    func getAllSessions() -> [ProductivitySession] {
        return sessions
    }
    
    // Method to add a new session
    func addSession(_ session: ProductivitySession) {
        sessions.append(session)
        saveSessions()
        
        // Check if we have enough data to train the ML model
        if sessions.count >= minSessionsForAI {
            NotificationModelTrainer.shared.trainModel(from: sessions)
        }
        
        // Check if we should share data
        checkAndShareDataIfNeeded()
    }
    
    // Helper method to save sessions to UserDefaults
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "productivitySessions")
        }
    }
    
    // Helper method to load sessions from UserDefaults
    private func loadSessions() {
        if let savedSessions = UserDefaults.standard.data(forKey: "productivitySessions"),
           let decodedSessions = try? JSONDecoder().decode([ProductivitySession].self, from: savedSessions) {
            sessions = decodedSessions
        }
    }
    
    // The existing debug method for recording a productive session
    func recordProductiveSession() {
        let now = Date()
        let calendar = Calendar.current
        
        let session = ProductivitySession(
            timestamp: now,
            duration: TimeInterval.random(in: 900...3600),  // 15-60 min
            dayOfWeek: calendar.component(.weekday, from: now),
            engagement: Float.random(in: 0.5...1.0),
            taskType: "study",
            difficulty: 3,
            completionPercentage: 0.8,
            userEnergyLevel: 3
        )
        
        addSession(session)
    }
    
    // Add initializer to load saved sessions
    init() {
        loadSessions()
        loadOrCreateModel()
        
        // Load data sharing preference from UserDefaults
        self.dataShareOptIn = UserDefaults.standard.bool(forKey: "dataShareOptIn")
    }
    
    func recordProductiveSession(
        duration: TimeInterval = 10*60,
        engagement: Float = 1.0,
        taskType: String? = nil,
        difficulty: Int? = nil,
        completionPercentage: Float? = nil,
        location: String? = nil,
        userEnergyLevel: Int? = nil
    ) {
        let session = ProductivitySession(
            timestamp: Date(),
            duration: duration,
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            engagement: engagement,
            taskType: taskType,
            difficulty: difficulty,
            completionPercentage: completionPercentage,
            userEnergyLevel: userEnergyLevel
        )
        
        productivitySessions.append(session)
        
        // Keep only the most recent sessions
        if productivitySessions.count > maxStoredSessions {
            productivitySessions.removeFirst(productivitySessions.count - maxStoredSessions)
        }
        
        saveSessions()
        
        // If we have enough data, update the model
        if productivitySessions.count >= minSessionsForAI {
            updateAIModel()
        }
    }
    
    func getOptimalNotificationTimes() -> [DateComponents] {
        // If we have enough data for AI prediction, use it
        if productivitySessions.count >= minSessionsForAI && aiModel != nil {
            return getPredictedNotificationTimes()
        }
        
        // Otherwise fall back to statistical analysis
        return getStatisticalNotificationTimes()
    }
    
    private func getPredictedNotificationTimes() -> [DateComponents] {
        do {
            // Use the generated class from your .mlmodel file
            let model = try NotificationTimePredictor()
            let calendar = Calendar.current
            let now = Date()
            let dayOfWeek = calendar.component(.weekday, from: now)
            let hour = calendar.component(.hour, from: now)
            let isWeekend = (dayOfWeek == 1 || dayOfWeek == 7) ? 1 : 0
            
            let prediction = try model.prediction(input: [
                "dayOfWeek": dayOfWeek,
                "hour": hour,
                "isWeekend": isWeekend,
                "duration": 600.0,
                "engagement": Double(getAverageRecentEngagement())
            ])
            
            // Get predicted optimal hour
            let predictedHour = prediction.optimalHour1
            
            // Create first notification at predicted time
            var components1 = DateComponents()
            components1.hour = predictedHour
            components1.minute = prediction.optimalMinute1
            
            // Create second notification 8 hours after the first (or another logic)
            var components2 = DateComponents()
            components2.hour = prediction.optimalHour2
            components2.minute = prediction.optimalMinute2
            
            return [components1, components2]
        } catch {
            print("ML prediction error: \(error)")
            return getStatisticalNotificationTimes()
        }
    }
    
    private func getStatisticalNotificationTimes() -> [DateComponents] {
        // If we don't have enough data, return default times
        guard productivitySessions.count >= minSessionsForAnalysis else {
            return getDefaultNotificationTimes()
        }
        
        // Extract hour components from all sessions
        let hourData = productivitySessions.map { Calendar.current.component(.hour, from: $0.timestamp) }
        
        // Count frequency of each hour, weighted by engagement
        var hourFrequency: [Int: Float] = [:]
        for (index, hour) in hourData.enumerated() {
            hourFrequency[hour, default: 0] += productivitySessions[index].engagement
        }
        
        // Find the top productive hours
        let sortedHours = hourFrequency.sorted { $0.value > $1.value }
        
        // Create notification times before the two most productive hours
        var notificationTimes: [DateComponents] = []
        
        // Take the two most productive hours and set notifications 1 hour before each
        for i in 0..<min(2, sortedHours.count) {
            let productiveHour = sortedHours[i].key
            var components = DateComponents()
            
            // Set reminder 1 hour before productive time
            let reminderHour = (productiveHour - 1 + 24) % 24
            
            components.hour = reminderHour
            components.minute = 0
            notificationTimes.append(components)
        }
        
        // If we couldn't get two times, fill with defaults
        while notificationTimes.count < 2 {
            notificationTimes.append(contentsOf: getDefaultNotificationTimes())
        }
        
        return Array(notificationTimes.prefix(2))
    }
    
    private func loadOrCreateModel() {
        // Check for existing model in documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                         in: .userDomainMask).first!
        let modelURL = documentsDirectory.appendingPathComponent("NotificationTimePredictor.mlmodel")
        if FileManager.default.fileExists(atPath: modelURL.path) {
            self.mlModelURL = modelURL
            print("Loaded existing model from \(modelURL.path)")
        } else {
            print("No existing model found")
        }
    }
    
    private func updateAIModel() {
        // Only attempt training if we have enough data
        guard productivitySessions.count >= minSessionsForAI else { return }
        // Train a new model
        if let newModelURL = NotificationModelTrainer.shared.trainModel(from: productivitySessions) {
            self.mlModelURL = newModelURL
            print("Updated ML model saved at \(newModelURL.path)")
        }
    }
    
    private func getAverageRecentEngagement() -> Float {
        // Get average engagement from the last week
        let oneWeekAgo = Date().addingTimeInterval(-7*24*60*60)
        let recentSessions = productivitySessions.filter { $0.timestamp > oneWeekAgo }
        
        if recentSessions.isEmpty {
            return 0.5 // Default medium engagement
        }
        
        let totalEngagement = recentSessions.reduce(0) { $0 + $1.engagement }
        return totalEngagement / Float(recentSessions.count)
    }
    
    private func getDefaultNotificationTimes() -> [DateComponents] {
        // Default to 9 AM and 5 PM if no data available
        let morning = DateComponents(hour: 9, minute: 0)
        let evening = DateComponents(hour: 17, minute: 0)
        return [morning, evening]
    }
    
    func exportTrainingData() -> URL? {
        guard !productivitySessions.isEmpty else { return nil }
        
        let csvHeader = "dayOfWeek,hour,isWeekend,duration,engagement,taskType,difficulty,completionPercentage,location,energyLevel,optimalHour\n"
        var csvContent = csvHeader
        
        for session in productivitySessions {
            let isWeekend = session.isWeekend ? "1" : "0"
            let hour = session.hour
            let optimalHour = (hour - 1 + 24) % 24 // 1 hour before productive time
            
        }
        
        // Save to documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("productivity_data.csv")
        
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to export data: \(error)")
            return nil
        }
    }
    
    // MARK: - Data Sharing Functions
    
    /// Anonymizes data by removing any personally identifiable information
    private func anonymizeSessionData(_ sessions: [ProductivitySession]) -> [AnonymizedSession] {
        // Convert actual dates to relative time offsets
        let oldestDate = sessions.map { $0.timestamp }.min() ?? Date()
        
        return sessions.map { session in
            let daysSinceFirst = Calendar.current.dateComponents([.day], from: oldestDate, to: session.timestamp).day ?? 0
            
            return AnonymizedSession(
                relativeDayOffset: daysSinceFirst,
                dayOfWeek: session.dayOfWeek,
                hour: Calendar.current.component(.hour, from: session.timestamp),
                duration: Int(session.duration),
                engagement: session.engagement,
                taskType: session.taskType,
                difficulty: session.difficulty,
                completionPercentage: session.completionPercentage,
                userEnergyLevel: session.userEnergyLevel
            )
        }
    }
    
    /// Simple struct for anonymized session data
    struct AnonymizedSession: Codable {
        let relativeDayOffset: Int
        let dayOfWeek: Int
        let hour: Int
        let duration: Int
        let engagement: Float
        let taskType: String?
        let difficulty: Int?
        let completionPercentage: Float?
        let userEnergyLevel: Int?
    }
    
    /// Check if conditions are met to share data and do so if needed
    func checkAndShareDataIfNeeded() {
        // Only proceed if user has opted in
        guard dataShareOptIn else { return }
        
        // Check if we have enough data and if enough time has passed since last share
        let now = Date()
        let lastShare = Date(timeIntervalSince1970: lastDataShareDate)
        let timePassedSinceLastShare = now.timeIntervalSince(lastShare)
        
        if sessions.count >= minSessionsForAI && (lastDataShareDate == 0 || timePassedSinceLastShare >= dataShareInterval) {
        }
    }
    
    /// Prepare and share anonymized data
    func shareAnonymizedData() -> Bool {
        guard sessions.count >= minSessionsForAnalysis else { return false }
        
        // Anonymize the session data
        let anonymizedData = anonymizeSessionData(sessions)
        
        // Get device info for model training context (no personal identifiers)
        let deviceContext = getDeviceContext()
        
        // Create the final payload
        let dataPayload = DataSharePayload(
            deviceContext: deviceContext,
            sessions: anonymizedData,
            dataVersion: "1.0"
        )
        
        // Serialize to JSON
        guard let jsonData = try? JSONEncoder().encode(dataPayload) else {
            print("Failed to encode data for sharing")
            return false
        }
        
        // UPDATED: Send to server instead of just saving locally
        sendDataToServer(jsonData)
        
        // Still save locally as a backup
        if saveAnonymizedData(jsonData) {
            // Update the last share date
            lastDataShareDate = Date().timeIntervalSince1970
            return true
        }
        
        return false
    }
    
    /// Send anonymized data to the server
    private func sendDataToServer(_ jsonData: Data) {
        guard let url = URL(string: "http://bitbyte.lol/api/submit-study-data") else {
            print("Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending data: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Data successfully sent to server")
                } else {
                    print("Server returned error: \(httpResponse.statusCode)")
                }
            }
        }
        task.resume()
    }
    
    /// Get generic device context information (non-identifying)
    private func getDeviceContext() -> DeviceContext {
        #if os(iOS)
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        #elseif os(macOS)
        let deviceType = "desktop"
        #else
        let deviceType = "unknown"
        #endif
        
        return DeviceContext(
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            deviceType: deviceType,
            locale: Locale.current.language.languageCode?.identifier ?? "unknown",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )
    }
    
    /// Save anonymized data locally for demo purposes
    private func saveAnonymizedData(_ data: Data) -> Bool {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent("anonymized_data_\(Date().timeIntervalSince1970).json")
        
        do {
            try data.write(to: fileURL)
            print("Anonymized data saved to: \(fileURL.path)")
            return true
        } catch {
            print("Failed to save anonymized data: \(error)")
            return false
        }
    }
    
    /// Structure for the complete data payload
    struct DataSharePayload: Codable {
        let deviceContext: DeviceContext
        let sessions: [AnonymizedSession]
        let dataVersion: String
    }
    
    /// Device context information for ML training
    struct DeviceContext: Codable {
        let osVersion: String
        let deviceType: String
        let locale: String
        let appVersion: String
    }
}
