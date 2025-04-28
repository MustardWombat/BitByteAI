import SwiftUI
import CloudKit
import CoreML
import PhotosUI // Add for photo picker

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

    var body: some View {
        ScrollView {
            ZStack {
                StarOverlay()
                VStack(spacing: 24) {
                    Text("Profile")
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
            }
        }
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
        .sheet(isPresented: $showDataSharingInfo) {
            DataSharingInfoView(isPresented: $showDataSharingInfo)
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
            location: ["home", "library", "coffee shop"].randomElement(),
            userEnergyLevel: Int.random(in: 2...5)
        )
        
        ProductivityTracker.shared.addSession(session)
        updateMLStatus()
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
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