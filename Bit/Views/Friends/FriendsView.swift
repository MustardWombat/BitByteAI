import SwiftUI
import CloudKit  // Ensure CloudKit is imported

struct FriendsView: View {
    @State private var allUsers: [CKRecord] = []  // Stores fetched user records
    @State private var isLoadingUsers: Bool = false
    @State private var weeklyStudyData: [String: Int] = [:] // Map userID to totalMinutes
    private let friendsManager = FriendsManager()
    
    var body: some View {
        VStack {
            Text("Friends")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Text("Manage your friends and view all accounts:")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            if isLoadingUsers {
                ProgressView("Loading users...")
            } else {
                List {
                    ForEach(allUsers, id: \.recordID) { record in
                        VStack(alignment: .leading) {
                            Text(record["username"] as? String ?? "No Username")
                                .font(.headline)
                            if let userID = record["userID"] as? String,
                               let minutes = weeklyStudyData[userID] {
                                Text("Weekly Study: \(minutes) minutes")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("No study data available")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear {
            // Add yourself as an example user
            let exampleUser = CKRecord(recordType: "User")
            exampleUser["username"] = "James Williams" as CKRecordValue
            exampleUser["userID"] = "example-user-id" as CKRecordValue
            allUsers.append(exampleUser)

            // Fetch real users from CloudKit
            isLoadingUsers = true
            friendsManager.fetchAllUsers { records, error in
                DispatchQueue.main.async {
                    isLoadingUsers = false
                    if let records = records {
                        allUsers.append(contentsOf: records)
                        fetchStudyData()
                    } else if let error = error {
                        print("Error fetching users: \(error)")
                    }
                }
            }
        }
    }

    private func fetchStudyData() {
        friendsManager.fetchWeeklyStudyData { data, error in
            DispatchQueue.main.async {
                if let data = data {
                    weeklyStudyData = Dictionary(uniqueKeysWithValues: data.map { ($0.userID, $0.totalMinutes) })
                } else if let error = error {
                    print("Error fetching study data: \(error)")
                }
            }
        }
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
