import SwiftUI
import CloudKit

private struct LevelPillWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct FriendsView: View {
    @AppStorage("profileUsername") private var storedUsername: String = ""
    @AppStorage("profileEmoji") private var profileEmoji: String = "😀"
    @State private var profileLevel: Int? = nil
    @State private var allUsers: [CKRecord] = []
    @State private var isLoadingUsers: Bool = false
    @State private var username: String = ""
    @State private var showingUsernamePrompt = false
    @State private var errorMessage: String?
    @State private var friendIDs: Set<String> = []
    @State private var showAddFriendOverlay = false
    @State private var currentUserStreak: Int? = nil
    @State private var friendLevels: [String: Int] = [:]
    @State private var levelPillWidth: CGFloat = 0
    private let friendsManager = CloudFriendsManager()

    var body: some View {
        ZStack {
            if storedUsername.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                        .padding(.bottom, 16)
                    Text("You must be logged in to view your friends.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.bottom, 12)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
            } else {
                VStack {
                    Text("Friends")
                        .font(.largeTitle)
                        .bold()
                        .padding()

                    // Add Friend button
                    HStack {
                        Spacer()
                        Button {
                            showAddFriendOverlay = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.title)
                                .padding()
                        }
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }

                    if isLoadingUsers {
                        ProgressView("Loading friends data...")
                    } else {
                        List {
                            // Your Profile section - use the locally saved Username
                            Section("Your Profile") {
                                if !storedUsername.isEmpty {
                                    HStack(spacing: 16) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                Text(profileEmoji)
                                                    .font(.largeTitle)
                                                    .foregroundColor(.white)
                                            )
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(storedUsername)")
                                                .font(.headline)
                                            Text("(You)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        VStack(spacing: 4) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill").foregroundColor(.yellow)
                                                Text(profileLevel != nil ? String(profileLevel!) : String(UserDefaults.standard.integer(forKey: "XPModel.level"))).bold().foregroundColor(.white)
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 12)
                                            .background(Capsule().fill(Color.green))
                                            .background(GeometryReader { geo in
                                                Color.clear.preference(key: LevelPillWidthKey.self, value: geo.size.width)
                                            })
                                            .frame(minWidth: 60)
                                            .frame(width: levelPillWidth)

                                            HStack(spacing: 4) {
                                                Image(systemName: "flame.fill")
                                                    .foregroundColor(.white)
                                                Text(currentUserStreak != nil ? String(currentUserStreak!) : "?")
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 12)
                                            .background(Capsule().fill(Color.orange))
                                        }
                                    }
                                    .padding(.vertical, 8)
                                } else {
                                    Text("No profile found")
                                        .foregroundColor(.gray)
                                }
                            }

                            // Friends section
                            Section("Friends") {
                                ForEach(allUsers.filter {
                                    let uid = $0["userID"] as? String
                                    return uid != UserDefaults.standard.string(forKey: "UserID")
                                }, id: \.recordID) { record in
                                    let uid = record["userID"] as? String ?? ""
                                    let emoji = record["profileEmoji"] as? String ?? "😀"
                                    let friendLevel = friendLevels[uid]
                                    HStack {
                                        Text(emoji)
                                            .font(.title2)
                                        Text(record["username"] as? String ?? "Unknown")
                                            .font(.headline)
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill").foregroundColor(.yellow)
                                            Text(friendLevel != nil ? String(friendLevel!) : "?").bold().foregroundColor(.white)
                                        }
                                        .frame(minWidth: 60)
                                        .frame(width: levelPillWidth)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 12)
                                        .background(Capsule().fill(Color.green))
                                        Spacer()
                                        if friendIDs.contains(uid) {
                                            Text("Added")
                                                .foregroundColor(.gray)
                                        } else {
                                            Button("Add") {
                                                let currentID = UserDefaults.standard.string(forKey: "UserID") ?? ""
                                                friendsManager.addFriend(currentUserID: currentID, friendID: uid) { success, _ in
                                                    if success {
                                                        friendIDs.insert(uid)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())  // make headers visible
                        .onPreferenceChange(LevelPillWidthKey.self) { value in
                            levelPillWidth = value
                        }

                        Button("Refresh Data") {
                            fetchAllData()
                        }
                        .padding()
                    }
                }

                // Overlay for adding a friend
                if showAddFriendOverlay {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("Add a Friend")
                            .font(.headline)
                        // list of users not already friends or self
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(allUsers.filter {
                                    let uid = $0["userID"] as? String ?? ""
                                    return uid != UserDefaults.standard.string(forKey: "UserID") &&
                                           !friendIDs.contains(uid)
                                }, id: \.recordID) { record in
                                    let uid = record["userID"] as? String ?? ""
                                    let emoji = record["profileEmoji"] as? String ?? "😀"
                                    HStack {
                                        Text(emoji)
                                            .font(.title2)
                                        Text(record["username"] as? String ?? "Unknown")
                                        Spacer()
                                        Button("Add") {
                                            let currentID = UserDefaults.standard.string(forKey: "UserID") ?? ""
                                            friendsManager.addFriend(currentUserID: currentID, friendID: uid) { success, _ in
                                                if success {
                                                    friendIDs.insert(uid)
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        Button("Close") {
                            showAddFriendOverlay = false
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: 300, maxHeight: 400)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 10)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear {
            fetchAllData()
            fetchCurrentUserStreak()
            fetchUserLevelFromCloudKit()
        }
        .alert("Enter Your Username", isPresented: $showingUsernamePrompt) {
            TextField("Username", text: $username)
            Button("Save") { createUser() }
        } message: { Text("Please enter a username.") }
    }

    private func fetchAllData() {
        isLoadingUsers = true
        fetchUsers {
            // after users are loaded, fetch friend list
            let userID = UserDefaults.standard.string(forKey: "UserID") ?? ""
            friendsManager.fetchFriendList(currentUserID: userID) { ids, error in
                DispatchQueue.main.async {
                    if let ids = ids {
                        friendIDs = Set(ids)
                    }
                    // fetch each friend's level
                    for record in allUsers {
                        if let uid = record["userID"] as? String {
                            fetchLevel(for: uid)
                        }
                    }
                    isLoadingUsers = false
                }
            }
        }
    }

    private func fetchUsers(completion: @escaping () -> Void) {
        friendsManager.fetchAllUsers { records, error in
            DispatchQueue.main.async {
                if let records = records {
                    allUsers = records
                } else if let error = error {
                    errorMessage = "Error fetching users: \(error.localizedDescription)"
                }
                completion()
            }
        }
    }

    private func fetchCurrentUserStreak() {
        let localStreak = 0
        let localDate = Date.distantPast
        CloudKitManager.shared.syncStreakWithCloud(localStreak: localStreak, localDate: localDate) { streak in
            DispatchQueue.main.async {
                self.currentUserStreak = streak
            }
        }
    }

    private func createUser() {
        guard !username.isEmpty else {
            showingUsernamePrompt = true
            return
        }
        friendsManager.createUserRecord(username: username) { _, _ in
            fetchAllData()
        }
    }
    
    private func fetchUserLevelFromCloudKit() {
        let userID = CloudKitManager.shared.getUserID()
        
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProgress", predicate: predicate)
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 1
        
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
                    if let level = record["level"] as? Int {
                        self.profileLevel = level
                    }
                }
            case .failure(let error):
                print("Error fetching matched record: \(error)")
            }
        }
        
        operation.queryResultBlock = { result in
            // No action required on complete
            // You can handle completion result here if needed.
        }
        
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    private func fetchLevel(for userID: String) {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProgress", predicate: predicate)
        CKContainer.default().publicCloudDatabase.fetch(withQuery: query, inZoneWith: nil, desiredKeys: ["level"], resultsLimit: 1) { result in
            switch result {
            case .success(let (matchedResults, _)):
                if let recordResult = matchedResults.first?.1, case .success(let record) = recordResult, let level = record["level"] as? Int {
                    DispatchQueue.main.async {
                        friendLevels[userID] = level
                    }
                }
            case .failure(let error):
                // Optionally handle error
                print("Error fetching level: \(error)")
            }
        }
    }
}
