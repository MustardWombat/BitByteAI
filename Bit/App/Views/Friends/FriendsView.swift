import SwiftUI
import CloudKit

struct FriendsView: View {
    @AppStorage("profileUsername") private var storedUsername: String = ""
    @State private var allUsers: [CKRecord] = []
    @State private var isLoadingUsers: Bool = false
    @State private var username: String = ""
    @State private var showingUsernamePrompt = false
    @State private var errorMessage: String?
    @State private var friendIDs: Set<String> = []
    @State private var showAddFriendOverlay = false
    @State private var currentUserStreak: Int? = nil
    private let friendsManager = CloudFriendsManager()

    var body: some View {
        ZStack {
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
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "person.fill")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(storedUsername)")
                                            .font(.headline)
                                        Text("(You)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
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
                                HStack {
                                    Text(record["username"] as? String ?? "Unknown")
                                        .font(.headline)
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
                                HStack {
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
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear {
            fetchAllData()
            fetchCurrentUserStreak()
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
}
