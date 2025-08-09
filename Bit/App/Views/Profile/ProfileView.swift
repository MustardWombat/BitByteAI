import SwiftUI
import CloudKit
import CoreML
#if os(iOS)
import UIKit
import AuthenticationServices
import PhotosUI
#else
import AppKit
typealias UIImage = NSImage
// Added dummy declaration for PhotosPickerItem on non‑iOS platforms.
struct PhotosPickerItem {}
#endif

struct Profile: Codable {
    var name: String
}

struct ProfileView: View {
    @State private var name: String = ""
    @AppStorage("profileUsername") private var username: String = "" // Use AppStorage for username
    @State private var showAlert = false
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @AppStorage("profileName") private var storedName: String = ""
    @AppStorage("profileEmoji") private var profileEmoji: String = "😀" // Added profileEmoji AppStorage
    @State private var cloudLevel: Int? = nil

    @AppStorage("deviceNotificationsAllowed") private var deviceNotificationsAllowed: Bool = true

    @Environment(\.dismiss) private var dismiss // Add dismiss environment
    var isPresented: Binding<Bool>? = nil

    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var shopModel: ShopModel
    @EnvironmentObject var timerModel: StudyTimerModel // added
    
    private let profileKey = "UserProfile"
    private let recordID = CKRecord.ID(recordName: "UserProfile")
    private let recordType = "Profile"

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderTime1") private var reminderTime1Interval: Double = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("reminderTime2") private var reminderTime2Interval: Double = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("useDynamicReminders") private var useDynamicReminders: Bool = false

    @State private var reminderTime1UI: Date = Date()
    @State private var reminderTime2UI: Date = Date()
    
    // Debugging state
    @State private var showDebugInfo: Bool = false
    @State private var userProfileData: [String: String] = [:]
    @State private var isLoadingDebugData: Bool = false

    var body: some View {
        // Fetch app version and build number from Info.plist
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        
        ZStack {
            ScrollView {
                ZStack {
                    StarOverlay()
                    VStack(spacing: 24) {
                        Text(username.isEmpty ? "Profile" : (username))
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 20) // Reduced top padding since we have navigation

                        if isSignedIn {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Name:")
                                    Spacer()
                                    TextField(
                                        "Your Name",
                                        text: $name,
                                        onEditingChanged: { editing in
                                            if !editing { saveProfileToCloudKit() }
                                        }
                                    )
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 180)
                                    .submitLabel(.done)
                                }
                                // Username field
                                HStack {
                                    Text("Username:")
                                    Spacer()
                                    TextField(
                                        "Enter your username",
                                        text: $username,
                                        onEditingChanged: { editing in
                                            if !editing {
                                                saveProfileToCloudKit()
                                            }
                                        }
                                    )
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 180)
                                    .submitLabel(.done)
                                }
                                if username.isEmpty {
                                    Text("Username is required")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                                
                                // Profile Emoji picker added here
                                VStack(alignment: .leading) {
                                    Text("Profile Emoji")
                                    Picker("Profile Emoji", selection: $profileEmoji) {
                                        Text("😀").tag("😀")
                                        Text("🚀").tag("🚀")
                                        Text("🌟").tag("🌟")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 180)
                                }

                                // Display crucial information
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Coins: \(currencyModel.balance)")
                                        .font(.headline)
                                    Text("XP: \(xpModel.xp) / \(xpModel.xpForNextLevel)")
                                        .font(.headline)
                                    Text("Level: \(cloudLevel ?? xpModel.level)")
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
                                    // Remove fullName scope since we rely solely on usernames
                                    request.requestedScopes = []
                                },
                                onCompletion: { result in
                                    switch result {
                                    case .success:
                                        // Do not extract or set the full name; rely on the username field instead
                                        isSignedIn = true
                                        saveProfileToCloudKit()
                                        // fetch stats immediately
                                        CloudKitManager.shared.fetchUserProgress(
                                            xpModel: xpModel,
                                            currencyModel: currencyModel,
                                            timerModel: timerModel
                                        )
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
                        
                        // Sign Out button when signed in
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
                            
                            // Debug button to reset purchases
                            Button("Reset Purchases") {
                                shopModel.resetPurchases()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                        
                        // Study Reminder Settings section
                        VStack {
                            Text("Study Reminder Settings")
                                .font(.headline)
                            Text("Choose your preferred study reminder times:")
                                .font(.subheadline)
                            
                            Toggle("Allow Notifications on Device", isOn: $deviceNotificationsAllowed)
                                .onChange(of: deviceNotificationsAllowed) { newValue in
                                    if newValue {
                                        NotificationManager.shared.requestAuthorization()
                                    } else {
                                        NotificationManager.shared.cancelReminders()
                                    }
                                }
                                .padding(.bottom)
                            
                            Toggle("Enable Reminders", isOn: $notificationsEnabled)
                                .onChange(of: notificationsEnabled) { newValue in
                                    if newValue {
                                        NotificationManager.shared.requestAuthorization()
                                    }
                                    updateNotifications()
                                }
                            
                            Toggle("Use Smart Reminders", isOn: $useDynamicReminders)
                                .onChange(of: useDynamicReminders) { newValue in
                                    updateNotifications()
                                }
                            
                            if notificationsEnabled && !useDynamicReminders {
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
                        
                        // Version and Build Number display
                        Text("Version \(appVersion) (Build \(buildNumber))")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        
                        // Debug section
                        VStack {
                            HStack {
                                Text("CloudKit Debug Info")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showDebugInfo.toggle()
                                        if showDebugInfo {
                                            loadDebugData()
                                        }
                                    }
                                }) {
                                    Image(systemName: showDebugInfo ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                        .imageScale(.large)
                                }
                            }
                            
                            if showDebugInfo {
                                if isLoadingDebugData {
                                    ProgressView("Loading data...")
                                } else {
                                    VStack(alignment: .leading) {
                                        Group {
                                            Text("User Profile")
                                                .font(.subheadline)
                                                .bold()
                                                .padding(.top, 4)
                                            
                                            if userProfileData.isEmpty {
                                                Text("No profile data found")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            } else {
                                                ForEach(Array(userProfileData.keys.sorted()), id: \.self) { key in
                                                    HStack {
                                                        Text(key + ":")
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                        Spacer()
                                                        Text(userProfileData[key] ?? "")
                                                            .font(.caption)
                                                            .multilineTextAlignment(.trailing)
                                                    }
                                                    .padding(.vertical, 2)
                                                }
                                            }
                                        }
                                        
                                        Divider()
                                            .padding(.vertical, 8)
                                        
                                        Button("Refresh Debug Data") {
                                            loadDebugData()
                                        }
                                        .font(.caption)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 40) // Extra padding at bottom
                    }
                }
            }
            .refreshable {
                // reload profile and stats
                loadProfileFromCloudKit()
                CloudKitManager.shared.fetchUserProgress(
                    xpModel: xpModel,
                    currencyModel: currencyModel,
                    timerModel: timerModel
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Profile Saved"), message: Text("Your profile info is saved to CloudKit."), dismissButton: .default(Text("OK")))
            }
            .overlay(alignment: .topLeading) {
                HStack {
                    Button("Done") {
                        if let isPresented = isPresented {
                            isPresented.wrappedValue = false
                        } else {
                            dismiss()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 16)
                    .padding(.leading, 20)
                    Spacer()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadProfileFromCloudKit()
            reminderTime1UI = Date(timeIntervalSince1970: reminderTime1Interval)
            reminderTime2UI = Date(timeIntervalSince1970: reminderTime2Interval)
            updateNotifications()
            if !deviceNotificationsAllowed {
                NotificationManager.shared.cancelReminders()
            }
            fetchUserLevelFromCloudKit()
        }
        .onChange(of: isSignedIn) { signedIn in
            if (signedIn) {
                // pull stats from CloudKit instead of pushing
                CloudKitManager.shared.fetchUserProgress(
                    xpModel: xpModel,
                    currencyModel: currencyModel,
                    timerModel: timerModel
                )
            }
        }
    }

    // --- CloudKit Sync ---
    private func saveProfileToCloudKit() {
        // First check if signed into iCloud
        CKContainer.default().accountStatus { status, error in
            if status == .available {
                self.fetchUserRecordIDAndSaveProfile()
            } else {
                print("❌ iCloud account not available")
                self.showAlert = true // Update alert message
            }
        }
    }
    
    private func fetchUserRecordIDAndSaveProfile() {
        print("🌩️ Starting profile save to CloudKit...")
        let container = CKContainer.default()
        container.fetchUserRecordID { recordID, error in
            guard let recordID = recordID else { return }
            let userID = recordID.recordName
            let privateDB = container.privateCloudDatabase

            // Query for an existing UserProfile record
            let pred = NSPredicate(format: "userID == %@", userID)
            let query = CKQuery(recordType: "UserProfile", predicate: pred)
            privateDB.perform(query, inZoneWith: nil) { results, _ in
                // Use existing or create new
                let record: CKRecord = results?.first ?? CKRecord(recordType: "UserProfile")
                
                // Set or overwrite fields
                record["userID"]        = userID as CKRecordValue
                record["username"]      = self.username as CKRecordValue
                record["displayName"]   = self.name as CKRecordValue
                record["profileEmoji"]  = self.profileEmoji as CKRecordValue // Save profileEmoji
                record["lastLoginDate"] = Date() as CKRecordValue

                // Save (will update if record was fetched)
                self.performCloudKitSave(record, on: privateDB, attempts: 0)
            }
        }
    }
    
    private func performCloudKitSave(_ record: CKRecord, on database: CKDatabase, attempts: Int) {
        if attempts >= 3 {
            DispatchQueue.main.async {
                print("🌩️❌ Failed to save profile after 3 attempts")
            }
            return
        }
        
        database.save(record) { savedRecord, error in
            if let error = error {
                let ckError = error as NSError
                print("🌩️❌ CloudKit save error: \(error.localizedDescription), code: \(ckError.code)")
                
                // Retry for specific errors
                if [CKError.networkUnavailable.rawValue, 
                    CKError.serviceUnavailable.rawValue].contains(ckError.code) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        print("🌩️ Retrying save, attempt \(attempts + 1)")
                        self.performCloudKitSave(record, on: database, attempts: attempts + 1)
                    }
                }
            } else {
                print("🌩️✅ Profile saved successfully!")
                DispatchQueue.main.async {
                    self.showAlert = true
                    UserDefaults.standard.set(true, forKey: "hasCreatedCloudProfile")
                    // Also cache the record ID for faster access
                    UserDefaults.standard.set(record["userID"] as? String, forKey: "cachedCloudKitUserID")
                }
            }
        }
    }

    private func loadProfileFromCloudKit() {
        CKContainer.default().accountStatus { (status, error) in
            if status == .available {
                self.fetchUserRecordIDAndLoadProfile()
            } else {
                print("🌩️❌ iCloud account not available for profile loading: \(status)")
            }
        }
    }
    
    private func fetchUserRecordIDAndLoadProfile() {
        // Try to use cached ID first for performance
        if let cachedID = UserDefaults.standard.string(forKey: "cachedCloudKitUserID") {
            self.queryProfileWithUserID(cachedID)
            return
        }
        
        // Otherwise fetch from CloudKit
        CKContainer.default().fetchUserRecordID { recordID, error in
            guard let recordID = recordID else {
                print("🌩️❌ Error fetching user record ID: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let userID = recordID.recordName
            // Cache the ID for future use
            UserDefaults.standard.set(userID, forKey: "cachedCloudKitUserID")
            self.queryProfileWithUserID(userID)
        }
    }
    
    private func queryProfileWithUserID(_ userID: String) {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let records = records, let record = records.first {
                    self.name = record["displayName"] as? String ?? ""
                    self.username = record["username"] as? String ?? ""
                    self.profileEmoji = record["profileEmoji"] as? String ?? "😀" // Load profileEmoji
                    
                    self.isSignedIn = true
                } else if let ckError = error as? CKError {
                    print("🌩️❌ CloudKit fetch error: \(ckError)")
                }
            }
        }
    }

    private func deleteProfileFromCloudKit() {
        // Use the cached ID if available
        if let cachedID = UserDefaults.standard.string(forKey: "cachedCloudKitUserID") {
            self.queryAndDeleteProfileWithUserID(cachedID)
            return
        }
        
        // Otherwise fetch from CloudKit
        CKContainer.default().fetchUserRecordID { recordID, error in
            guard let recordID = recordID else {
                print("🌩️❌ Error fetching user record ID for deletion: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let userID = recordID.recordName
            self.queryAndDeleteProfileWithUserID(userID)
        }
    }
    
    private func queryAndDeleteProfileWithUserID(_ userID: String) {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records, let record = records.first {
                CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("🌩️❌ Error deleting CloudKit profile: \(error)")
                    } else {
                        print("🌩️✅ CloudKit profile deleted.")
                        
                        // Clear cached user ID
                        UserDefaults.standard.removeObject(forKey: "cachedCloudKitUserID")
                        
                        // Also delete progress data
                        self.deleteProgressFromCloudKit()
                    }
                }
            }
        }
    }

    private func deleteProgressFromCloudKit() {
        let userID = UserDefaults.standard.string(forKey: "cachedCloudKitUserID") ?? ""
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProgress", predicate: predicate)
        
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records, let record = records.first {
                CKContainer.default().privateCloudDatabase.delete(withRecordID: record.recordID) { _, error in
                    if let error = error {
                        print("Error deleting progress data: \(error)")
                    } else {
                        print("Progress data deleted.")
                    }
                }
            }
        }
    }

    private func updateNotifications() {
        // Only use manually set reminder times; remove dynamic reminder logic
        let comp1 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime1Interval))
        let comp2 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime2Interval))
        let reminderComponents = [comp1, comp2]
        
        // Update NotificationManager only if enabled and device notifications allowed
        if notificationsEnabled && deviceNotificationsAllowed {
            NotificationManager.shared.reminderTimes = reminderComponents
            NotificationManager.shared.updateReminders()
        } else {
            NotificationManager.shared.cancelReminders()
        }
    }
    
    // Debug data loading functions
    private func loadDebugData() {
        isLoadingDebugData = true
        userProfileData.removeAll()
        let userID = UserDefaults.standard.string(forKey: "cachedCloudKitUserID") ?? ""
        loadUserProfileDebugData(userID: userID) {
            DispatchQueue.main.async {
                self.isLoadingDebugData = false
            }
        }
    }
    
    private func loadUserProfileDebugData(userID: String, completion: @escaping () -> Void) {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.userProfileData["Error"] = error.localizedDescription
                    completion()
                    return
                }
                
                if let record = records?.first {
                    // Convert all fields to string representation
                    for (key, value) in record.allValues() {
                        if key == "profileImage", let asset = value as? CKAsset {
                            self.userProfileData[key] = "[Image Asset: \(asset.fileURL?.lastPathComponent)]"
                        } else {
                            self.userProfileData[key] = String(describing: value)
                        }
                    }
                    
                    // Add record metadata - use the system property not a custom field
                    self.userProfileData["recordID"] = record.recordID.recordName
                    self.userProfileData["systemCreationDate"] = record.creationDate?.description ?? "N/A"
                    self.userProfileData["systemModificationDate"] = record.modificationDate?.description ?? "N/A"
                } else {
                    self.userProfileData["Status"] = "No profile record found"
                }
                
                completion()
            }
        }
    }
    
    private func signOut() {
        // Reset sign-in state
        isSignedIn = false

        // Clear profile data
        name = ""
        username = ""
        profileEmoji = "😀" // Reset profileEmoji to default
        cloudLevel = nil

        // --- Reset all stats on logout ---
        currencyModel.balance = 0
        xpModel.resetXP()
        shopModel.resetPurchases()
        // ...if you have more trackers, reset them here...

        // Clear cached CloudKit identifiers
        UserDefaults.standard.removeObject(forKey: "cachedCloudKitUserID")
        UserDefaults.standard.removeObject(forKey: "hasCreatedCloudProfile")

        // Optionally delete profile from CloudKit
        deleteProfileFromCloudKit()

        showAlert = true // Show confirmation
    }
    
    private func signIn() {
        // Check if signed into iCloud
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                if status == .available {
                    // User is signed in to iCloud
                    isSignedIn = true
                    saveProfileToCloudKit()
                    // fetch stats immediately
                    CloudKitManager.shared.fetchUserProgress(
                        xpModel: xpModel,
                        currencyModel: currencyModel,
                        timerModel: timerModel
                    )
                
                } else {
                    // Show an alert or handle the error
                    print("❌ iCloud sign-in failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func fetchUserLevelFromCloudKit() {
        let userID = CloudKitManager.shared.getUserID()
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProgress", predicate: predicate)
        let container = CKContainer.default()

        // First try private database
        container.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            if let record = records?.first, let level = record["level"] as? Int {
                print("✅ Found level in private database: \(level)")
                DispatchQueue.main.async { self.cloudLevel = level }
            } else {
                // If not found, try public database
                container.publicCloudDatabase.perform(query, inZoneWith: nil) { pubRecords, pubError in
                    if let pubRecord = pubRecords?.first, let pubLevel = pubRecord["level"] as? Int {
                        print("✅ Found level in public database: \(pubLevel)")
                        DispatchQueue.main.async { self.cloudLevel = pubLevel }
                    } else {
                        print("❌ No level found in either database.")
                    }
                }
            }
        }
    }
}

// Add extension to help with CloudKit record values
extension CKRecord {
    func allValues() -> [String: Any] {
        var result: [String: Any] = [:]
        for key in allKeys() {
            result[key] = self[key]
        }
        return result
    }
}

// Data sharing info view (kept because it is no longer referenced, but not harmful)
struct DataSharingInfoView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("About Data Sharing")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Help improve the app's AI features by contributing anonymized study data.")
                            .font(.headline)
                    }
                    
                    Group {
                        Text("What is shared:")
                            .font(.headline)
                        
                        BulletPoint(text: "Study session timing (hour of day, day of week)")
                        BulletPoint(text: "Study session duration")
                        BulletPoint(text: "Task types and difficulty ratings")
                        BulletPoint(text: "Engagement levels")
                    }
                    
                    Group {
                        Text("What is NOT shared:")
                            .font(.headline)
                        
                        BulletPoint(text: "Your name or personal information")
                        BulletPoint(text: "Exact dates or times")
                        BulletPoint(text: "Task content or specific titles")
                        BulletPoint(text: "Device identifiers")
                        BulletPoint(text: "Specific locations")
                    }
                    
                    Group {
                        Text("How it's used:")
                            .font(.headline)
                        
                        Text("Your anonymized data helps train our machine learning models to better predict optimal study times, recommended study durations, and personalized task suggestions.")
                            .padding(.bottom, 10)
                        
                        Text("Data is anonymized on your device before being sent. You can opt out anytime in settings.")
                    }
                    
                    Spacer()
                }
                .padding()
            }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            #else
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            #endif
        }
    }
}

// Helper view for bullet points
struct BulletPoint: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("•")
                .font(.headline)
            Text(text)
            Spacer()
        }
        .padding(.leading)
    }
}
