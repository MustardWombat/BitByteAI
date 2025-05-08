import Foundation
import CloudKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

class CloudKitManager {
    static let shared = CloudKitManager()
    
    // Use the default container
    let container = CKContainer.default()
    
    // Get or create a user ID that remains consistent
    func getUserID() -> String {
        if let existingID = UserDefaults.standard.string(forKey: "cloudkit_user_id") {
            return existingID
        } else {
            // Generate a new ID only once
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "cloudkit_user_id")
            return newID
        }
    }
    
    // Setup initial sync (call this when app starts)
    func setupSync(xpModel: XPModel, currencyModel: CurrencyModel, timerModel: StudyTimerModel) {
        // First sync right away
        syncUserProgressToCloud(xpModel: xpModel, currencyModel: currencyModel, timerModel: timerModel)
        
        // Then schedule periodic syncs
        schedulePeriodicalSync(xpModel: xpModel, currencyModel: currencyModel, timerModel: timerModel)
    }
    
    // Save common data periodically to ensure it's backed up
    func schedulePeriodicalSync(xpModel: XPModel, currencyModel: CurrencyModel, timerModel: StudyTimerModel) {
        // Setup timer to sync data once per hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.syncUserProgressToCloud(xpModel: xpModel, currencyModel: currencyModel, timerModel: timerModel)
        }
    }
    
    // Sync user progress to CloudKit - using correct property access
    func syncUserProgressToCloud(xpModel: XPModel, currencyModel: CurrencyModel, timerModel: StudyTimerModel) {
        let record = CKRecord(recordType: "UserProgress")
        let userID = getUserID()
        
        record["userID"] = userID as CKRecordValue
        record["level"] = xpModel.level as CKRecordValue
        record["xp"] = xpModel.xp as CKRecordValue
        record["coinBalance"] = currencyModel.balance as CKRecordValue
        
        // Use totalTimeStudied converted to minutes
        let totalMinutes = Double(timerModel.totalTimeStudied / 60) // Convert seconds to minutes
        record["totalStudyMinutes"] = totalMinutes as CKRecordValue
        
        // Use current date for lastStudyDate since the property was removed
        record["lastStudyDate"] = Date() as CKRecordValue
        
        // Use dailyStreak directly from timerModel
        let studyStreak = timerModel.dailyStreak
        record["studyStreak"] = studyStreak as CKRecordValue
        
        // Create daily minutes array from weekly study minutes
        let dailyMinutes = timerModel.createDailyMinutesArray()
        record["daily_Minutes"] = dailyMinutes as CKRecordValue
        
        container.privateCloudDatabase.save(record) { (savedRecord, error) in
            if let error = error {
                print("Error saving user progress: \(error)")
            } else {
                print("User progress saved successfully")
            }
        }
    }
    
    // Match the function signature exactly as it's being called in your code
    func syncUserProgressToCloud(_ xpModel: XPModel, _ currencyModel: CurrencyModel, _ timerModel: StudyTimerModel) {
        // Call the primary implementation
        syncUserProgressToCloud(xpModel: xpModel, currencyModel: currencyModel, timerModel: timerModel)
    }
    
    // Also add a dedicated function for calling this from outside contexts
    func syncUserProgress(xpModel: XPModel, currencyModel: CurrencyModel, timerModel: StudyTimerModel) {
        syncUserProgressToCloud(xpModel: xpModel, currencyModel: currencyModel, timerModel: timerModel)
    }
    
    private func calculateStudyStreak(lastStudyDate: Date?) -> Int {
        // Basic implementation - you can enhance this based on your app's tracking
        guard let lastStudyDate = lastStudyDate else { return 0 }
        
        // Check if studied today or yesterday
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let studyDay = calendar.startOfDay(for: lastStudyDate)
        
        if calendar.isDate(studyDay, inSameDayAs: today) {
            return UserDefaults.standard.integer(forKey: "currentStudyStreak")
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  calendar.isDate(studyDay, inSameDayAs: yesterday) {
            return UserDefaults.standard.integer(forKey: "currentStudyStreak")
        } else {
            return 0 // Streak broken
        }
    }
    
    // Save temporary image files for CloudKit assets
    func saveImageToTempLocation(image: Any) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".jpg")
        
        #if os(iOS)
        if let uiImage = image as? UIImage, let data = uiImage.jpegData(compressionQuality: 0.8) {
            try? data.write(to: url)
        }
        #endif
        
        return url
    }
    
    // Also add a function to save user profile (moved from BitApp.swift)
    func syncUserProfileToCloud(
        username: String,
        displayName: String,
        profileImage: UIImage? = nil
    ) {
        let record = CKRecord(recordType: "UserProfile")
        let userID = getUserID()
        
        record["userID"] = userID as CKRecordValue
        record["username"] = username as CKRecordValue
        record["displayName"] = displayName as CKRecordValue
        record["creationDate"] = Date() as CKRecordValue
        record["lastLoginDate"] = Date() as CKRecordValue
        
        // Save profile image if available
        if let profileImage = profileImage {
            #if os(iOS)
            let imageAsset = CKAsset(fileURL: saveImageToTempLocation(image: profileImage))
            record["profileImage"] = imageAsset
            #endif
        }
        
        container.privateCloudDatabase.save(record) { (savedRecord, error) in
            if let error = error {
                print("Error saving user profile: \(error)")
            } else {
                print("User profile saved successfully")
            }
        }
    }
    
    // Add no-parameter version of syncUserProfileToCloud that reads from UserDefaults
    func syncUserProfileToCloud() {
        // Get values from UserDefaults
        let username = UserDefaults.standard.string(forKey: "profileUsername") ?? "User"
        let displayName = UserDefaults.standard.string(forKey: "profileName") ?? ""
        
        // Get profile image if available
        var profileImage: UIImage? = nil
        #if os(iOS)
        if let imageData = UserDefaults.standard.data(forKey: "profileImageData"),
           let image = UIImage(data: imageData) {
            profileImage = image
        } else {
            // Create a default profile image with user's initials
            profileImage = createDefaultProfileImage(for: username)
        }
        #endif
        
        // Call the main implementation with these values
        syncUserProfileToCloud(username: username, displayName: displayName, profileImage: profileImage)
    }
    
    #if os(iOS)
    // Helper function to create a default profile image with user's initials
    private func createDefaultProfileImage(for username: String) -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw background
            UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Get user initials
            let initials = String(username.prefix(1).uppercased())
            
            // Draw initials
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            
            let attributedText = NSAttributedString(string: initials, attributes: attributes)
            
            // Center the text in the circle
            let textRect = CGRect(x: 0, y: (size.height - 80) / 2, width: size.width, height: 80)
            attributedText.draw(in: textRect)
        }
    }
    #endif
}

// Updated extension with proper methods for StudyTimerModel 
extension StudyTimerModel {
    // Helper method to create daily minutes array based on actual properties
    func createDailyMinutesArray() -> [Int] {
        // Create a daily minutes array with total weekly minutes distributed to today
        let today = Calendar.current.component(.weekday, from: Date()) - 1 // 0-based index (0 = Sunday)
        var dailyArray = [0, 0, 0, 0, 0, 0, 0] // Initialize with zeros for each day
        
        // Place all minutes on today's entry for simplicity
        if today >= 0 && today < 7 {
            dailyArray[today] = self.weeklyStudyMinutes
        }
        
        return dailyArray
    }
}
