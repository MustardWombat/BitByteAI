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
    @AppStorage("profileImageData") private var profileImageData: Data? // Store profile image in AppStorage

    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var shopModel: ShopModel
    
    // Change to observed object to enable bindings
    @ObservedObject private var productivityTracker = ProductivityTracker.shared
    
    private let profileKey = "UserProfile"
    private let recordID = CKRecord.ID(recordName: "UserProfile")
    private let recordType = "Profile"

    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderTime1") private var reminderTime1Interval: Double = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("reminderTime2") private var reminderTime2Interval: Double = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("useDynamicReminders") private var useDynamicReminders: Bool = false

    @State private var reminderTime1UI: Date = Date()
    @State private var reminderTime2UI: Date = Date()
    
    // ML tracking state
    @State private var sessionsCollected: Int = 0
    @State private var sessionsNeeded: Int = 20
    @State private var mlFeaturesAvailable: [String] = []
    @State private var isTrainingModel: Bool = false
    
    // Data sharing state
    @State private var showDataSharingInfo = false
    @State private var showDataSharedConfirmation = false

    // Profile picture state
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    // Debugging state
    @State private var showDebugInfo: Bool = false
    @State private var userProfileData: [String: String] = [:]
    @State private var userProgressData: [String: String] = [:]
    @State private var isLoadingDebugData: Bool = false

    var body: some View {
        ScrollView {
            ZStack {
                StarOverlay()
                VStack(spacing: 24) {
                    Text(username.isEmpty ? "Profile" : (username))
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)

                    // Profile Picture Section
                    VStack {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 5)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 100, height: 100)
                                .overlay(Text("Add Photo").foregroundColor(.white))
                        }
                        Button("Change Picture") {
                            showImagePicker = true
                        }
                        .padding(.top, 8)
                    }

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
                            // New username field
                            HStack {
                                Text("Username:")
                                Spacer()
                                TextField("Enter your username", text: $username)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 180)
                            }
                            if username.isEmpty {
                                Text("Username is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.leading)
                            }
                            Button("Save to Cloud") {
                                saveProfileToCloudKit()
                                showAlert = true
                            }
                            .disabled(username.isEmpty) // Disable button if username is empty
                            .padding()
                            .background(username.isEmpty ? Color.gray : Color.green)
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
                                // Remove fullName scope since we rely solely on usernames
                                request.requestedScopes = []
                            },
                            onCompletion: { result in
                                switch result {
                                case .success:
                                    // Do not extract or set the full name; rely on the username field instead
                                    isSignedIn = true
                                    saveProfileToCloudKit()
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
                        
                        if useDynamicReminders {
                            Text("Smart reminders will be set based on your productivity patterns")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Button("Record Productive Session (Debug)") {
                                ProductivityTracker.shared.recordProductiveSession()
                                updateNotifications()
                            }
                            .font(.caption)
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    
                    // ML Insights section
                    VStack {
                        Text("ML Insights")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("Study Pattern Data")
                                .font(.subheadline)
                                .bold()
                            
                            HStack {
                                Text("Sessions Collected:")
                                Spacer()
                                Text("\(sessionsCollected)/\(sessionsNeeded)")
                                    .foregroundColor(sessionsCollected >= sessionsNeeded ? .green : .gray)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: geometry.size.width, height: 10)
                                        .opacity(0.3)
                                        .foregroundColor(.gray)
                                    
                                    Rectangle()
                                        .frame(width: min(CGFloat(sessionsCollected) / CGFloat(sessionsNeeded) * geometry.size.width, geometry.size.width), height: 10)
                                        .foregroundColor(.green)
                                }
                                .cornerRadius(5)
                            }
                            .frame(height: 10)
                            
                            Text("Available ML Features:")
                                .padding(.top, 8)
                            
                            ForEach(mlFeaturesAvailable, id: \.self) { feature in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(feature)
                                }
                            }
                            
                            if mlFeaturesAvailable.isEmpty {
                                Text("No ML features available yet")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            if sessionsCollected >= sessionsNeeded && !isTrainingModel {
                                Button("Train ML Model") {
                                    trainMLModel()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.top, 8)
                            } else if isTrainingModel {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Training model...")
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                        
                        Button("Record Test Productivity Session") {
                            recordTestSession()
                        }
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                    .padding()
                    
                    // Data Sharing section
                    VStack {
                        Text("Help Improve the AI")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Share Anonymous Study Data", isOn: $productivityTracker.dataShareOptIn)
                                .onChange(of: productivityTracker.dataShareOptIn) { newValue in
                                    if newValue {
                                        // User opted in, show info sheet
                                        showDataSharingInfo = true
                                    }
                                }
                            
                            Text("Share anonymized study patterns to help improve the ML models for everyone.")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if productivityTracker.dataShareOptIn {
                                HStack {
                                    Button(action: {
                                        showDataSharingInfo = true
                                    }) {
                                        Label("Learn More", systemImage: "info.circle")
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if productivityTracker.shareAnonymizedData() {
                                            showDataSharedConfirmation = true
                                            
                                            // Auto-hide confirmation after 3 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                showDataSharedConfirmation = false
                                            }
                                        }
                                    }) {
                                        Label("Share Now", systemImage: "square.and.arrow.up")
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            if showDataSharedConfirmation {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Data shared successfully")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    
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
                                    
                                    Group {
                                        Text("User Progress")
                                            .font(.subheadline)
                                            .bold()
                                            .padding(.top, 4)
                                        
                                        if userProgressData.isEmpty {
                                            Text("No progress data found")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            ForEach(Array(userProgressData.keys.sorted()), id: \.self) { key in
                                                HStack {
                                                    Text(key + ":")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                    Spacer()
                                                    Text(userProgressData[key] ?? "")
                                                        .font(.caption)
                                                        .multilineTextAlignment(.trailing)
                                                }
                                                .padding(.vertical, 2)
                                            }
                                        }
                                    }
                                    
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
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Profile Saved"), message: Text("Your profile info is saved to CloudKit."), dismissButton: .default(Text("OK")))
                }
                .background(Color.black.ignoresSafeArea())
                .onAppear {
                    loadProfileFromCloudKit()
                    reminderTime1UI = Date(timeIntervalSince1970: reminderTime1Interval)
                    reminderTime2UI = Date(timeIntervalSince1970: reminderTime2Interval)
                    updateNotifications()
                    updateMLStatus()
                }
                // Conditional PhotoPicker Sheet
                #if os(iOS)
                .sheet(isPresented: $showImagePicker) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text("Select a Profile Picture")
                    }
                    .onChange(of: selectedPhotoItem) { newItem in
                        if let newItem = newItem {
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    profileImage = image
                                    profileImageData = data // Save image data to AppStorage
                                }
                            }
                        }
                    }
                }
                #else
                .sheet(isPresented: $showImagePicker) {
                    Text("Photo picker not available on this platform")
                }
                #endif
            }
        }
        .sheet(isPresented: $showDataSharingInfo) {
            DataSharingInfoView(isPresented: $showDataSharingInfo)
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
        
        // Get the default CloudKit container
        let container = CKContainer.default()
        
        // Fetch the user's record ID directly from CloudKit
        container.fetchUserRecordID { recordID, error in
            guard let recordID = recordID else {
                print("🌩️❌ Error fetching user record ID: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let userID = recordID.recordName
            let privateDB = container.privateCloudDatabase
            
            // Create a record with the right record type
            let record = CKRecord(recordType: "UserProfile")
            
            // Set the fields
            record["userID"] = userID as CKRecordValue
            record["username"] = self.username as CKRecordValue
            record["displayName"] = self.name as CKRecordValue
            record["lastLoginDate"] = Date() as CKRecordValue
            
            // Save profile image
            if let profileImage = self.profileImage {
                #if os(iOS)
                if let imageData = profileImage.jpegData(compressionQuality: 0.7) {
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".jpg")
                    try? imageData.write(to: tempURL)
                    
                    let imageAsset = CKAsset(fileURL: tempURL)
                    record["profileImage"] = imageAsset
                    
                    // Clean up the temp file after upload
                    DispatchQueue.global().async {
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                }
                #endif
            }
            
            print("🌩️ Using container: \(container.containerIdentifier ?? "unknown")")
            
            // Update retry mechanism to be more robust
            self.performCloudKitSave(record, on: privateDB, attempts: 0)
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
                    
                    // Load profile image if available
                    if let profileAsset = record["profileImage"] as? CKAsset,
                       let fileURL = profileAsset.fileURL,
                       let imageData = try? Data(contentsOf: fileURL) {
                        #if os(iOS)
                        self.profileImage = UIImage(data: imageData)
                        self.profileImageData = imageData
                        #endif
                    }
                    
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
        // If using dynamic notifications, get times from ProductivityTracker
        var reminderComponents: [DateComponents]
        
        if useDynamicReminders {
            reminderComponents = ProductivityTracker.shared.getOptimalNotificationTimes()
        } else {
            // Otherwise use the manually set times
            let comp1 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime1Interval))
            let comp2 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime2Interval))
            reminderComponents = [comp1, comp2]
        }
        
        // Update NotificationManager only if enabled
        if notificationsEnabled {
            NotificationManager.shared.reminderTimes = reminderComponents
            NotificationManager.shared.updateReminders()
        } else {
            NotificationManager.shared.cancelReminders()
        }
    }
    
    // ML functionality methods
    private func updateMLStatus() {
        let status = MLManager.shared.getDataCollectionStatus()
        sessionsCollected = status.sessionsCollected
        sessionsNeeded = status.sessionsNeeded
        
        mlFeaturesAvailable = []
        
        if MLManager.shared.isFeatureAvailable(.notificationTiming) {
            mlFeaturesAvailable.append("Smart Notification Timing")
        }
        
        if MLManager.shared.isFeatureAvailable(.studyDuration) {
            mlFeaturesAvailable.append("Optimal Study Duration")
        }
        
        if MLManager.shared.isFeatureAvailable(.taskRecommendation) {
            mlFeaturesAvailable.append("Task Recommendations")
        }
    }
    
    private func trainMLModel() {
        isTrainingModel = true
        
        DispatchQueue.global(qos: .background).async {
            let sessions = ProductivityTracker.shared.getAllSessions()
            let modelURL = NotificationModelTrainer.shared.trainModel(from: sessions)
            
            DispatchQueue.main.async {
                self.isTrainingModel = false
                if modelURL != nil {
                    MLManager.shared.loadModels()
                    self.updateMLStatus()
                }
            }
        }
    }
    
    private func recordTestSession() {
        let now = Date()
        let calendar = Calendar.current
        
        let session = ProductivityTracker.ProductivitySession(
            timestamp: now,
            duration: TimeInterval.random(in: 900...3600),
            dayOfWeek: calendar.component(.weekday, from: now),
            engagement: Float.random(in: 0.5...1.0),
            taskType: ["reading", "problem-solving", "memorization"].randomElement(),
            difficulty: Int.random(in: 1...5),
            completionPercentage: Float.random(in: 0.5...1.0),
            userEnergyLevel: Int.random(in: 2...5)
        )
        
        ProductivityTracker.shared.addSession(session)
        updateMLStatus()
    }
    
    // Debug data loading functions
    private func loadDebugData() {
        isLoadingDebugData = true
        userProfileData.removeAll()
        userProgressData.removeAll()
        
        let userID = UserDefaults.standard.string(forKey: "cachedCloudKitUserID") ?? ""
        loadUserProfileDebugData(userID: userID) {
            loadUserProgressDebugData(userID: userID) {
                DispatchQueue.main.async {
                    self.isLoadingDebugData = false
                }
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
    
    private func loadUserProgressDebugData(userID: String, completion: @escaping () -> Void) {
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProgress", predicate: predicate)
        
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.userProgressData["Error"] = error.localizedDescription
                    completion()
                    return
                }
                
                if let record = records?.first {
                    // Convert all fields to string representation
                    for (key, value) in record.allValues() {
                        if key == "daily_Minutes", let minutes = value as? [Int] {
                            let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                            var formattedMinutes = ""
                            for (index, min) in minutes.enumerated() {
                                if index < daysOfWeek.count {
                                    formattedMinutes += "\(daysOfWeek[index]): \(min)min "
                                }
                            }
                            self.userProgressData[key] = formattedMinutes
                        } else {
                            self.userProgressData[key] = String(describing: value)
                        }
                    }
                    
                    // Add record metadata
                    self.userProgressData["recordID"] = record.recordID.recordName
                    self.userProgressData["creationDate"] = record.creationDate?.description ?? "N/A"
                    self.userProgressData["modificationDate"] = record.modificationDate?.description ?? "N/A"
                } else {
                    self.userProgressData["Status"] = "No progress record found"
                }
                
                completion()
            }
        }
    }
    
    private func signOut() {
        // Reset sign-in state
        isSignedIn = false
        
        // Clear user data
        name = ""
        username = ""
        profileImage = nil
        profileImageData = nil
        
        // Clear cached data
        UserDefaults.standard.removeObject(forKey: "cachedCloudKitUserID")
        UserDefaults.standard.removeObject(forKey: "hasCreatedCloudProfile")
        
        // Optionally delete profile from CloudKit
        deleteProfileFromCloudKit()
        
        showAlert = true // Show confirmation
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

// Data sharing info view
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
