import SwiftUI
import CloudKit

struct FriendsView: View {
    @State private var allUsers: [CKRecord] = []
    @State private var isLoadingUsers: Bool = false
    @State private var username: String = ""
    @State private var showingUsernamePrompt = false
    @State private var errorMessage: String?
    @State private var friendIDs: Set<String> = []
    @State private var showAddFriendOverlay = false
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
                            if let name = UserDefaults.standard.string(forKey: "Username") {
                                Text("\(name) (You)")
                                    .font(.headline)
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
        .onAppear { fetchAllData() }
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
