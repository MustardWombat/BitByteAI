import Foundation
import CloudKit

class CloudFriendsManager {
    // Use the correct container explicitly
    private let container: CKContainer
    private let isCloudAvailable: Bool
    
    init(containerIdentifier: String? = nil) {
        // Determine the app's real bundle ID and use it for the container
        let bundleID = Bundle.main.bundleIdentifier ?? "com.jameswilliams.Bit"
        let containerID = containerIdentifier ?? "iCloud.\(bundleID)"
        
        print("DEBUG: App bundle ID: \(bundleID)")
        print("DEBUG: Using container ID: \(containerID)")
        
        container = CKContainer(identifier: containerID)
        
        // Check if CloudKit is available
        isCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        
        // Print debug info
        print("DEBUG: Using CloudKit container: \(container.containerIdentifier ?? "unknown")")
    }
    
    func testConnection(completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            let error = NSError(
                domain: "CloudFriendsManager", 
                code: 1, 
                userInfo: [NSLocalizedDescriptionKey: "iCloud is not available"]
            )
            completion(false, error)
            return
        }
        
        // Instead of saving a record, just check if we can fetch the container's info
        container.accountStatus { status, error in
            if let error = error {
                print("DEBUG: CloudKit connection test failed: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            if status == .available {
                print("DEBUG: CloudKit connection successful! Account status: \(status)")
                completion(true, nil)
            } else {
                let statusError = NSError(
                    domain: "CloudFriendsManager", 
                    code: 2, 
                    userInfo: [NSLocalizedDescriptionKey: "iCloud account not available. Status: \(status)"]
                )
                print("DEBUG: CloudKit connection failed: Account status \(status)")
                completion(false, statusError)
            }
        }
    }
    
    func fetchAllUsers(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        // Check if CloudKit is available
        guard isCloudAvailable else {
            let error = NSError(
                domain: "CloudFriendsManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "iCloud is not available. Please sign in to your iCloud account."]
            )
            completion(nil, error)
            return
        }
        
        // We'll fetch users from the public database
        let publicDB = container.publicCloudDatabase
        
        // Create a query for all Users records - updated name to match CloudKit Dashboard
        let query = CKQuery(recordType: "Users", predicate: NSPredicate(value: true))
        
        // Perform the query with error handling
        publicDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                let cloudError = error as NSError
                print("Error fetching users: \(error.localizedDescription), code: \(cloudError.code)")
                
                // Return cached data if available
                if let cachedUsers = self.loadCachedUsers() {
                    print("Using cached user data")
                    completion(cachedUsers, nil)
                } else {
                    completion(nil, error)
                }
                return
            }
            
            // Cache the results for offline use
            self.cacheUsers(records ?? [])
            
            completion(records, nil)
        }
    }
    
    func fetchWeeklyStudyData(completion: @escaping ([(userID: String, totalMinutes: Int)]?, Error?) -> Void) {
        // Check if CloudKit is available
        guard isCloudAvailable else {
            let error = NSError(
                domain: "CloudFriendsManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "iCloud is not available. Please sign in to your iCloud account."]
            )
            completion(nil, error)
            return
        }
        
        let publicDB = container.publicCloudDatabase
        
        // Get the current week's start date
        let calendar = Calendar.current
        let today = Date()
        guard let weekStartDay = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            completion(nil, NSError(domain: "CloudFriendsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine week start date"]))
            return
        }
        
        // Create query for weekly study data - updated name to match CloudKit Dashboard
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!
        let predicate = NSPredicate(format: "weekStartDate >= %@", twoWeeksAgo as NSDate)
        let query = CKQuery(recordType: "weekly_Study_Data", predicate: predicate)
        
        // Print the schema of the first record for debugging
        publicDB.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                let cloudError = error as NSError
                print("Error fetching weekly study data: \(error.localizedDescription), code: \(cloudError.code)")
                
                // Return cached data if available
                if let cachedData = self.loadCachedStudyData() {
                    print("Using cached study data")
                    completion(cachedData, nil)
                } else {
                    completion(nil, error)
                }
                return
            }
            
            guard let records = records else {
                completion([], nil)
                return
            }
            
            // Debug information about the first record
            if let firstRecord = records.first {
                print("DEBUG: weekly_Study_Data record keys: \(firstRecord.allKeys().joined(separator: ", "))")
                firstRecord.allKeys().forEach { key in
                    print("DEBUG: field '\(key)' = \(String(describing: firstRecord[key]))")
                }
            }
            
            // Extract userID and totalMinutes from each record
            let studyData = records.compactMap { record -> (String, Int)? in
                // Use exact field names from CloudKit schema
                guard let userID = record["userID"] as? String,
                      let totalMinutes = record["totalMinutes"] as? Int else {
                    return nil
                }
                return (userID, totalMinutes)
            }
            
            // Cache the results for offline use
            self.cacheStudyData(studyData)
            
            completion(studyData, nil)
        }
    }
    
    func createUserRecord(username: String, completion: @escaping (Bool, Error?) -> Void) {
        // Check if CloudKit is available
        guard isCloudAvailable else {
            // Create a local user ID and save locally
            let userID = UUID().uuidString
            UserDefaults.standard.set(userID, forKey: "UserID")
            UserDefaults.standard.set(username, forKey: "Username")
            completion(true, nil)
            return
        }
        
        let publicDB = container.publicCloudDatabase
        
        // Create a unique user ID
        let userID = UUID().uuidString
        
        // Save userID to UserDefaults for future reference
        UserDefaults.standard.set(userID, forKey: "UserID")
        UserDefaults.standard.set(username, forKey: "Username")
        
        // Create user record with corrected field names
        let record = CKRecord(recordType: "Users")
        record["User_ID"] = userID as CKRecordValue
        record["Username"] = username as CKRecordValue
        
        publicDB.save(record) { _, error in
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                // Despite CloudKit error, still consider this successful locally
                completion(true, error)
                return
            }
            
            completion(true, nil)
        }
    }
    
    // MARK: - Cache Management
    
    private let usersCacheKey = "CachedUsers"
    private let studyDataCacheKey = "CachedStudyData"
    
    private func cacheUsers(_ records: [CKRecord]) {
        // We can't directly encode CKRecord, so let's extract relevant data
        let userData = records.compactMap { record -> [String: Any]? in
            // Update field names to match CloudKit schema
            guard let userID = record["User_ID"] as? String,
                  let username = record["Username"] as? String else {
                return nil
            }
            return ["userID": userID, "username": username]
        }
        UserDefaults.standard.set(userData, forKey: usersCacheKey)
    }
    
    private func loadCachedUsers() -> [CKRecord]? {
        guard let userData = UserDefaults.standard.array(forKey: usersCacheKey) as? [[String: Any]] else {
            return nil
        }
        
        // Convert back to CKRecords (simplified version)
        return userData.compactMap { data -> CKRecord? in
            guard let userID = data["userID"] as? String,
                  let username = data["username"] as? String else {
                return nil
            }
            
            let record = CKRecord(recordType: "Users")
            record["User_ID"] = userID as CKRecordValue  // Keep this as User_ID for Users record type
            record["Username"] = username as CKRecordValue // Keep this as Username for Users record type
            return record
        }
    }
    
    private func cacheStudyData(_ data: [(userID: String, totalMinutes: Int)]) {
        let studyDict = data.map { ["userID": $0.userID, "totalMinutes": $0.totalMinutes] }
        UserDefaults.standard.set(studyDict, forKey: studyDataCacheKey)
    }
    
    private func loadCachedStudyData() -> [(userID: String, totalMinutes: Int)]? {
        guard let studyData = UserDefaults.standard.array(forKey: studyDataCacheKey) as? [[String: Any]] else {
            return nil
        }
        
        return studyData.compactMap { data -> (String, Int)? in
            guard let userID = data["userID"] as? String,
                  let totalMinutes = data["totalMinutes"] as? Int else {
                return nil
            }
            return (userID, totalMinutes)
        }
    }
}