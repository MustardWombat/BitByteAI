// Ensure that NotificationManager.swift is included in your target,
// or import its module if you have placed it in a separate module (e.g. import Services)
import SwiftUI
import CloudKit

#if os(iOS)
import AuthenticationServices
#endif

struct Profile: Codable {
    var name: String
}

struct ProfileView: View {
    @State private var name: String = ""
    @State private var showAlert = false
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @AppStorage("profileName") private var storedName: String = ""

    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var shopModel: ShopModel

    private let profileKey = "UserProfile"
    private let recordID = CKRecord.ID(recordName: "UserProfile")
    private let recordType = "Profile"

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderTime1") private var reminderTime1Interval: Double = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("reminderTime2") private var reminderTime2Interval: Double = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970

    @State private var reminderTime1UI: Date = Date()
    @State private var reminderTime2UI: Date = Date()

    var body: some View {
        ScrollView {  // added ScrollView to enable scrolling
            ZStack {
                StarOverlay() // Add the starry background
                VStack(spacing: 24) {
                    Text("Profile")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)

                    if isSignedIn {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Name:")
                                Spacer()
                                TextField("Your Name", text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 180)
                            }
                            Button("Save to Cloud") {
                                saveProfileToCloudKit()
                                showAlert = true
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            // Display crucial information
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Coins: \(currencyModel.balance)")
                                    .font(.headline)
                                Text("XP: \(xpModel.xp) / \(xpModel.xpForNextLevel)")
                                    .font(.headline)
                                Text("Level: \(xpModel.level)")
                                    .font(.headline)
                                Text("Purchases:")
                                    .font(.headline)
                                if shopModel.purchasedItems.isEmpty {
                                    Text("No items purchased yet.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(shopModel.purchasedItems) { item in
                                        Text("\(item.name) x\(item.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                    } else {
                        #if os(iOS)
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName]
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let auth):
                                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                                        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                                            .compactMap { $0 }
                                            .joined(separator: " ")
                                        name = fullName.isEmpty ? name : fullName
                                        isSignedIn = true // Set the global flag
                                        saveProfileToCloudKit()
                                    }
                                case .failure:
                                    break
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.whiteOutline)
                        .frame(height: 45)
                        .padding(.horizontal, 40)
                        #else
                        Button("Sign In") {
                            signIn()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        #endif
                    }
                    // NEW: Add a Sign Out button when signed in
                    if isSignedIn {
                        Button("Sign Out") {
                            signOut()
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top, 20)
                    }

                    // Debug Notifications section
                    VStack {
                        Text("Debug Notifications")
                            .font(.headline)
                        Button("Send Debug Notification") {
                            NotificationManager.shared.sendDebugNotification()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    // NEW: Study Reminder Settings section added under Debug Notifications
                    VStack {
                        Text("Study Reminder Settings")
                            .font(.headline)
                        Text("Choose your preferred study reminder times:")
                            .font(.subheadline)
                        Toggle("Enable Reminders", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { newValue in
                                if newValue {
                                    NotificationManager.shared.requestAuthorization()
                                }
                                updateNotifications()
                            }
                        if notificationsEnabled {
                            DatePicker("Reminder 1", selection: $reminderTime1UI, displayedComponents: .hourAndMinute)
                                .onChange(of: reminderTime1UI) { newValue in 
                                    reminderTime1Interval = newValue.timeIntervalSince1970
                                    updateNotifications()
                                }
                            DatePicker("Reminder 2", selection: $reminderTime2UI, displayedComponents: .hourAndMinute)
                                .onChange(of: reminderTime2UI) { newValue in
                                    reminderTime2Interval = newValue.timeIntervalSince1970
                                    updateNotifications()
                                }
                        }
                    }
                    .padding()
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Profile Saved"), message: Text("Your profile info is saved to CloudKit."), dismissButton: .default(Text("OK")))
                }
                .background(Color.black.ignoresSafeArea())
                .onAppear {
                    loadProfileFromCloudKit() // or your preferred load method
                    
                    // Sync UI state with AppStorage on appear
                    reminderTime1UI = Date(timeIntervalSince1970: reminderTime1Interval)
                    reminderTime2UI = Date(timeIntervalSince1970: reminderTime2Interval)
                    
                    updateNotifications() // ensures notifications are updated on view appear
                }
            }
        }
    }

    // --- CloudKit Sync ---
    private func saveProfileToCloudKit() {
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["name"] = name as CKRecordValue

        CKContainer.default().privateCloudDatabase.save(record) { _, error in
            if let error = error {
                print("CloudKit save error: \(error)")
            }
        }
    }

    private func loadProfileFromCloudKit() {
        CKContainer.default().privateCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record,
               let cloudName = record["name"] as? String,
               !cloudName.isEmpty {
                DispatchQueue.main.async {
                    self.name = cloudName
                    self.isSignedIn = true
                    // No local backup is used anymore
                }
            } else if let ckError = error as? CKError, ckError.code == .unknownItem {
                print("No CloudKit profile found.")
            } else if let error = error {
                print("CloudKit fetch error: \(error)")
            }
        }
    }

    private func signOut() {
        // Delete cloud-saved profile so that login state is cleared on relaunch.
        deleteProfileFromCloudKit()
        isSignedIn = false
        name = ""
    }

    private func deleteProfileFromCloudKit() {
        CKContainer.default().privateCloudDatabase.delete(withRecordID: recordID) { _, error in
            if let error = error {
                print("Error deleting CloudKit profile: \(error)")
            } else {
                print("CloudKit profile deleted.")
            }
        }
    }

    private func signIn() {
        #if os(iOS)
        // iOS-specific Sign In with Apple implementation
        #else
        // Mac-specific implementation or fallback
        isSignedIn = true
        saveProfileToCloudKit()
        #endif
    }

    private func updateNotifications() {
        let comp1 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime1Interval))
        let comp2 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime2Interval))
        // Update NotificationManager only if enabled
        if notificationsEnabled {
            NotificationManager.shared.reminderTimes = [comp1, comp2]
            NotificationManager.shared.updateReminders()
        } else {
            NotificationManager.shared.cancelReminders()
        }
    }
}
