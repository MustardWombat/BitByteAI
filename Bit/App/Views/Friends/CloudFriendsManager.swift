import Foundation
import CloudKit

class CloudFriendsManager {
    private let container: CKContainer
    private let isCloudAvailable: Bool

    init() {
        // Use the default container matching your entitlements
        container = CKContainer.default()
        isCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
    }

    func testConnection(completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(false, NSError(domain: "CloudFriendsManager", code: 1, userInfo: nil))
            return
        }
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                completion(status == .available, error)
            }
        }
    }

    func fetchAllUsers(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(nil, NSError(domain: "CloudFriendsManager", code: 1, userInfo: nil))
            return
        }
        let publicDB = container.publicCloudDatabase
        let query = CKQuery(recordType: "Users", predicate: NSPredicate(value: true))
        publicDB.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                completion(records, error)
            }
        }
    }

    func createUserRecord(username: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            let id = UUID().uuidString
            UserDefaults.standard.set(id, forKey: "UserID")
            UserDefaults.standard.set(username, forKey: "Username")
            completion(true, nil)
            return
        }
        let publicDB = container.publicCloudDatabase
        let userID = UUID().uuidString
        UserDefaults.standard.set(userID, forKey: "UserID")
        UserDefaults.standard.set(username, forKey: "Username")
        let record = CKRecord(recordType: "Users")
        record["userID"] = userID as CKRecordValue
        record["username"] = username as CKRecordValue
        publicDB.save(record) { _, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        }
    }

    // MARK: - Cache Management
    
    private let usersCacheKey = "CachedUsers"
    
    private func cacheUsers(_ records: [CKRecord]) {
        let userData = records.compactMap { record -> [String: Any]? in
            guard let userID = record["userID"] as? String,
                  let username = record["username"] as? String else {
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
        
        return userData.compactMap { data -> CKRecord? in
            guard let userID = data["userID"] as? String,
                  let username = data["username"] as? String else {
                return nil
            }
            
            let record = CKRecord(recordType: "Users")
            record["userID"] = userID as CKRecordValue
            record["username"] = username as CKRecordValue
            return record
        }
    }
}