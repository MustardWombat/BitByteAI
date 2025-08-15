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
        if #available(iOS 15.0, *) {
            var allRecords: [CKRecord] = []
            let operation = CKQueryOperation(query: query)
            operation.recordMatchedBlock = { recordID, result in
                switch result {
                case .success(let record):
                    allRecords.append(record)
                case .failure(let error):
                    // Optionally handle per-record error, but we'll skip here
                    print("Failed to fetch record with ID \(recordID): \(error)")
                }
            }
            operation.queryResultBlock = { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        completion(allRecords, nil)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            }
            publicDB.add(operation)
        } else {
            publicDB.perform(query, inZoneWith: nil) { records, error in
                DispatchQueue.main.async {
                    completion(records, error)
                }
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

    // Add a friend to the current user's 'friends' list
    func addFriend(currentUserID: String, friendID: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(false, NSError(domain: "CloudFriendsManager", code: 1, userInfo: nil))
            return
        }
        let publicDB = container.publicCloudDatabase
        let predicate = NSPredicate(format: "userID == %@", currentUserID)
        let query = CKQuery(recordType: "Users", predicate: predicate)
        
        if #available(iOS 15.0, *) {
            publicDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
                switch result {
                case .success(let (matchResults, _)):
                    if let firstResult = matchResults.first {
                        let (_, recordResult) = firstResult
                        switch recordResult {
                        case .success(let record):
                            var friends = record["friends"] as? [String] ?? []
                            if !friends.contains(friendID) {
                                friends.append(friendID)
                                record["friends"] = friends as CKRecordValue
                                publicDB.save(record) { _, saveError in
                                    DispatchQueue.main.async {
                                        completion(saveError == nil, saveError)
                                    }
                                }
                            } else {
                                DispatchQueue.main.async { completion(true, nil) }
                            }
                        case .failure(let fetchError):
                            DispatchQueue.main.async { completion(false, fetchError) }
                        }
                    } else {
                        DispatchQueue.main.async { completion(false, nil) }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { completion(false, error) }
                }
            }
        } else {
            publicDB.perform(query, inZoneWith: nil) { results, error in
                if let record = results?.first {
                    var friends = record["friends"] as? [String] ?? []
                    if !friends.contains(friendID) {
                        friends.append(friendID)
                        record["friends"] = friends as CKRecordValue
                        publicDB.save(record) { _, saveError in
                            DispatchQueue.main.async {
                                completion(saveError == nil, saveError)
                            }
                        }
                    } else {
                        DispatchQueue.main.async { completion(true, nil) }
                    }
                } else {
                    DispatchQueue.main.async { completion(false, error) }
                }
            }
        }
    }

    // Fetch the friend ID list for the current user
    func fetchFriendList(currentUserID: String, completion: @escaping ([String]?, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(nil, NSError(domain: "CloudFriendsManager", code: 1, userInfo: nil))
            return
        }
        let publicDB = container.publicCloudDatabase
        let predicate = NSPredicate(format: "userID == %@", currentUserID)
        let query = CKQuery(recordType: "Users", predicate: predicate)
        
        if #available(iOS 15.0, *) {
            publicDB.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1) { result in
                switch result {
                case .success(let (matchResults, _)):
                    if let firstResult = matchResults.first {
                        let (_, recordResult) = firstResult
                        switch recordResult {
                        case .success(let record):
                            let friends = record["friends"] as? [String] ?? []
                            DispatchQueue.main.async {
                                completion(friends, nil)
                            }
                        case .failure(let fetchError):
                            DispatchQueue.main.async {
                                completion(nil, fetchError)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil, nil)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        } else {
            publicDB.perform(query, inZoneWith: nil) { records, error in
                if let record = records?.first {
                    let friends = record["friends"] as? [String] ?? []
                    DispatchQueue.main.async {
                        completion(friends, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
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
