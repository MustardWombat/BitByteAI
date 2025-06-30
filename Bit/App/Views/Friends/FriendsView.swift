import SwiftUI
import CloudKit

struct FriendsView: View {
    @State private var allUsers: [CKRecord] = []
    @State private var isLoadingUsers: Bool = false
    @State private var username: String = ""
    @State private var showingUsernamePrompt = false
    @State private var errorMessage: String?
    private let friendsManager = CloudFriendsManager()

    var body: some View {
        VStack {
            Text("Friends")
                .font(.largeTitle)
                .bold()
                .padding()

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
                            ($0["userID"] as? String) != UserDefaults.standard.string(forKey: "UserID")
                        }, id: \.recordID) { record in
                            let name = record["username"] as? String ?? "Unknown"
                            Text(name)
                                .font(.headline)
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
            isLoadingUsers = false
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
