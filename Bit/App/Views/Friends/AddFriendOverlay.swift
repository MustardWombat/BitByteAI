import SwiftUI
import CloudKit

struct AddFriendOverlay: View {
    @Binding var showAddFriendOverlay: Bool
    @Binding var addFriendSearchText: String
    var allUsers: [CKRecord]
    var friendIDs: Set<String>
    var friendsManager: CloudFriendsManager
    var onFriendAdded: (String) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Done") { showAddFriendOverlay = false }
                    .padding(.leading)
                Spacer()
            }
            Text("Add a Friend")
                .font(.headline)
                .padding(.horizontal)
            TextField("Search users...", text: $addFriendSearchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(allUsers.filter {
                        let uid = $0["userID"] as? String ?? ""
                        let username = $0["username"] as? String ?? ""
                        let emoji = $0["profileEmoji"] as? String ?? ""
                        return uid != UserDefaults.standard.string(forKey: "UserID") &&
                               !friendIDs.contains(uid) &&
                               (addFriendSearchText.isEmpty ||
                                username.localizedCaseInsensitiveContains(addFriendSearchText) ||
                                emoji.contains(addFriendSearchText))
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
                                        onFriendAdded(uid)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .padding(.horizontal)
        }
        .padding(.top)
        .background(Color(UIColor.systemBackground))
        .shadow(radius: 10)
    }
}
