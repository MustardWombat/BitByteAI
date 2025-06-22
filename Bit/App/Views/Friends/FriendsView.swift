import SwiftUI
import CloudKit

struct FriendsView: View {
    @State private var allUsers: [CKRecord] = []
    @State private var isLoadingUsers: Bool = false
    @State private var weeklyStudyData: [String: Int] = [:]
    @State private var username: String = ""
    @State private var showingUsernamePrompt = false
    @State private var errorMessage: String?
    @State private var showMine: Bool = false  // new toggle
    private let friendsManager = CloudFriendsManager()
    
    var body: some View {
        VStack {
            Text("Friends")
                .font(.largeTitle)
                .bold()
                .padding()
            
            // new segmented picker
            Picker("", selection: $showMine) {
                Text("Friends").tag(false)
                Text("My Stats").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if showMine {
                // show only current user's stats, default to 0 if no record yet
                if let userID = UserDefaults.standard.string(forKey: "UserID") {
                    let minutes = weeklyStudyData[userID] ?? 0
                    VStack(spacing: 16) {
                        Text(UserDefaults.standard.string(forKey: "Username") ?? "You")
                            .font(.title2)
                            .bold()
                        Text("Weekly Study: \(minutes) minutes")
                            .font(.headline)
                    }
                    .padding()
                } else {
                    Text("No user registered")
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if isLoadingUsers {
                    ProgressView("Loading friends data...")
                } else {
                    List {
                        // Show current user at the top
                        if let userID = UserDefaults.standard.string(forKey: "UserID"), 
                           let minutes = weeklyStudyData[userID] {
                            VStack(alignment: .leading) {
                                Text("\(UserDefaults.standard.string(forKey: "Username") ?? "You") (You)")
                                    .font(.headline)
                                Text("Weekly Study: \(minutes) minutes")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Show other users
                        ForEach(allUsers, id: \.recordID) { record in
                            if let userID = record["userID"] as? String, 
                               UserDefaults.standard.string(forKey: "UserID") != userID {
                                VStack(alignment: .leading) {
                                    Text(record["username"] as? String ?? "Unknown")
                                        .font(.headline)
                                    if let minutes = weeklyStudyData[userID] {
                                        Text("Weekly Study: \(minutes) minutes")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("No study data this week")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    
                    Button(action: {
                        fetchAllData()
                    }) {
                        Label("Refresh Data", systemImage: "arrow.clockwise")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear {
            checkUserRegistration()
        }
        .alert("Enter Your Username", isPresented: $showingUsernamePrompt) {
            TextField("Username", text: $username)
            Button("Save") {
                createUser()
            }
        } message: {
            Text("Please enter a username to identify yourself to other users.")
        }
    }
    
    private func checkUserRegistration() {
        // First test CloudKit connection
        isLoadingUsers = true
        errorMessage = "Testing CloudKit connection..."
        
        friendsManager.testConnection { success, error in
            DispatchQueue.main.async {
                if success {
                    errorMessage = nil
                    if UserDefaults.standard.string(forKey: "UserID") == nil {
                        showingUsernamePrompt = true
                        isLoadingUsers = false
                    } else {
                        fetchAllData()
                    }
                } else {
                    isLoadingUsers = false
                    errorMessage = "CloudKit error: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
    
    private func createUser() {
        guard !username.isEmpty else {
            showingUsernamePrompt = true
            return
        }
        
        isLoadingUsers = true
        friendsManager.createUserRecord(username: username) { success, error in
            DispatchQueue.main.async {
                isLoadingUsers = false
                if success {
                    // seed a zero-minute entry for the new user
                    if let userID = UserDefaults.standard.string(forKey: "UserID") {
                        friendsManager.saveWeeklyStudyData(for: userID, totalMinutes: 0) { _ in
                            fetchAllData()
                        }
                    } else {
                        fetchAllData()
                    }
                } else {
                    errorMessage = "Failed to create user: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
    
    private func fetchAllData() {
        isLoadingUsers = true
        fetchUsers {
            fetchStudyData {
                isLoadingUsers = false
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
    
    private func fetchStudyData(completion: @escaping () -> Void) {
        friendsManager.fetchWeeklyStudyData { data, error in
            DispatchQueue.main.async {
                if let data = data {
                    weeklyStudyData = Dictionary(uniqueKeysWithValues: data.map { ($0.userID, $0.totalMinutes) })
                } else if let error = error {
                    errorMessage = "Error fetching study data: \(error.localizedDescription)"
                }
                completion()
            }
        }
    }
}
