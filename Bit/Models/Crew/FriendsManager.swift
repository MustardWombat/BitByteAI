import Foundation
import CloudKit  // added CloudKit import

// A simple enum to represent friend request status
enum FriendRequestStatus {
    case pending, accepted, rejected
}

// A struct representing a friend request
struct FriendRequest {
    let fromUser: String
    let toUser: String
    var status: FriendRequestStatus
}

// A struct to represent weekly study data
struct WeeklyStudyData {
    let userID: String
    let weekStartDate: Date
    let totalMinutes: Int
}

// The FriendsManager class is responsible for managing friend requests and friend lists.
class FriendsManager {
    // Storage for friend requests
    private var friendRequests: [FriendRequest] = []
    
    // Storage for friendships, where each user maps to a set of friend usernames
    private var friendships: [String: Set<String>] = [:]
    
    // Send a friend request from one user to another
    func sendRequest(from sender: String, to receiver: String) {
        // Check if there's already a friendship
        if friendships[sender]?.contains(receiver) == true {
            print("\(sender) and \(receiver) are already friends.")
            return
        }
        
        // Check if a request already exists
        if friendRequests.contains(where: { $0.fromUser == sender && $0.toUser == receiver && $0.status == .pending }) {
            print("Friend request already sent from \(sender) to \(receiver).")
            return
        }
        
        // Add new friend request
        friendRequests.append(FriendRequest(fromUser: sender, toUser: receiver, status: .pending))
        print("Friend request sent from \(sender) to \(receiver).")
    }
    
    // Accept a friend request from one user to another
    func acceptRequest(from sender: String, to receiver: String) {
        guard var request = friendRequests.first(where: { $0.fromUser == sender && $0.toUser == receiver && $0.status == .pending }) else {
            print("No pending friend request from \(sender) to \(receiver) found.")
            return
        }
        request.status = .accepted
        // Update the request in the list
        friendRequests = friendRequests.map { req in
            if req.fromUser == sender && req.toUser == receiver && req.status == .pending {
                return request
            }
            return req
        }
        
        // Add each other as friends
        friendships[sender, default: []].insert(receiver)
        friendships[receiver, default: []].insert(sender)
        print("\(receiver) accepted friend request from \(sender).")
    }
    
    // Reject a friend request from one user to another
    func rejectRequest(from sender: String, to receiver: String) {
        guard var request = friendRequests.first(where: { $0.fromUser == sender && $0.toUser == receiver && $0.status == .pending }) else {
            print("No pending friend request from \(sender) to \(receiver) found.")
            return
        }
        request.status = .rejected
        // Update the request in the list
        friendRequests = friendRequests.map { req in
            if req.fromUser == sender && req.toUser == receiver && req.status == .pending {
                return request
            }
            return req
        }
        print("\(receiver) rejected friend request from \(sender).")
    }
    
    // Remove a friend for a given user
    func removeFriend(user: String, friend: String) {
        guard friendships[user]?.contains(friend) == true else {
            print("\(friend) is not a friend of \(user).")
            return
        }
        friendships[user]?.remove(friend)
        friendships[friend]?.remove(user)
        print("\(friend) has been removed from \(user)'s friend list.")
    }
    
    // List all friends for a given user
    func listFriends(for user: String) -> [String] {
        return Array(friendships[user] ?? [])
    }
    
    // New function to find a user via CloudKit based on username.
    func findUser(username: String, completion: @escaping (CKRecord?, Error?) -> Void) {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(format: "username == %@", username)
        let query = CKQuery(recordType: "User", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let record = records?.first else {
                completion(nil, nil)
                return
            }
            completion(record, nil)
        }
    }
    
    // New function to fetch all users from CloudKit
    func fetchAllUsers(completion: @escaping ([CKRecord]?, Error?) -> Void) {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "User", predicate: predicate)
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            completion(records, error)
        }
    }
    
    // Save weekly study data to CloudKit
    func saveWeeklyStudyData(for userID: String, totalMinutes: Int, completion: @escaping (Error?) -> Void) {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let record = CKRecord(recordType: "WeeklyStudyData")
        record["userID"] = userID
        record["weekStartDate"] = Calendar.current.startOfDay(for: Date()) as CKRecordValue
        record["totalMinutes"] = totalMinutes as CKRecordValue
        
        publicDatabase.save(record) { _, error in
            completion(error)
        }
    }

    // Fetch weekly study data for all users
    func fetchWeeklyStudyData(completion: @escaping ([WeeklyStudyData]?, Error?) -> Void) {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "WeeklyStudyData", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records {
                let studyData = records.compactMap { record -> WeeklyStudyData? in
                    guard let userID = record["userID"] as? String,
                          let weekStartDate = record["weekStartDate"] as? Date,
                          let totalMinutes = record["totalMinutes"] as? Int else { return nil }
                    return WeeklyStudyData(userID: userID, weekStartDate: weekStartDate, totalMinutes: totalMinutes)
                }
                completion(studyData, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    // Create a new user record in CloudKit
    func createUserRecord(username: String, userID: String, completion: @escaping (Error?) -> Void) {
        let publicDatabase = CKContainer.default().publicCloudDatabase
        let record = CKRecord(recordType: "User")
        record["username"] = username
        record["userID"] = userID
        
        publicDatabase.save(record) { _, error in
            completion(error)
        }
    }
}
