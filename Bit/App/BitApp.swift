//  ContentView.swift
//  BitByteAI
//
//  Last edited 05/08/25.
//

#if DEBUG
#if canImport(StoreKitTest)
import StoreKitTest    // ← only import when StoreKitTest is available
#endif
#endif
import SwiftUI
import WidgetKit
import CloudKit

struct BitAppView: View {
    @StateObject var xpModel: XPModel
    @StateObject var miningModel: MiningModel
    @StateObject var timerModel: StudyTimerModel
    @StateObject var shopModel = ShopModel()
    @StateObject var civModel = CivilizationModel()
    @StateObject var categoriesModel = CategoriesViewModel()
    @StateObject var currencyModel = CurrencyModel()
    @StateObject var taskModel = TaskModel()

    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @State private var showSignInPrompt: Bool = false
    @State private var showSplash = true

    init() {
        let xp = XPModel()
        let mining = MiningModel()
        let currency = CurrencyModel()

        // Hook the mining reward to the currency model
        mining.awardCoins = { amount in
            currency.deposit(amount)
        }

        _xpModel = StateObject(wrappedValue: xp)
        _miningModel = StateObject(wrappedValue: mining)
        _timerModel = StateObject(wrappedValue: StudyTimerModel(xpModel: xp, miningModel: mining))
        _currencyModel = StateObject(wrappedValue: currency)
    }

    var body: some View {
        Group {
            if showSplash {
                // Show only the splash screen during initial loading
                SplashScreenOverlay()
                    .onAppear {
                        // Load critical data first
                        NSUbiquitousKeyValueStore.default.synchronize()
                        
                        // Hide splash after animation completes and data is loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showSplash = false
                            }
                            
                            // Load remaining data after splash screen is dismissed
                            DispatchQueue.main.async {
                                loadRemainingData()
                            }
                        }
                    }
            } else {
                // Show the main app content only after splash is dismissed
                AppContentView()
                    .environmentObject(xpModel)
                    .environmentObject(timerModel)
                    .environmentObject(shopModel)
                    .environmentObject(civModel)
                    .environmentObject(miningModel)
                    .environmentObject(categoriesModel)
                    .environmentObject(currencyModel)
                    .environmentObject(taskModel)
                    .onAppear {
                        if !showSignInPrompt && !isSignedIn {
                            checkUserProfileExists()
                        }
                    }
            }
        }
        .sheet(isPresented: $showSignInPrompt, onDismiss: {
            if isSignedIn {
                categoriesModel.mergeWithICloudData()
                CloudKitManager.shared.syncUserProfileToCloud()
            }
        }) {
            SignInPromptView(onSignIn: {
                isSignedIn = true
                showSignInPrompt = false
                categoriesModel.mergeWithICloudData()
                CloudKitManager.shared.syncUserProfileToCloud()
            }, onSkip: {
                showSignInPrompt = false
                createLocalUserProfile()
            })
        }
    }
    
    private func checkUserProfileExists() {
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase
        
        // Use consistent user ID
        let userID = CloudKitManager.shared.getUserID()
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking user profile: \(error)")
                    // Continue with sign-in prompt on error
                    self.showSignInPrompt = true
                    return
                }
                
                if let records = records, !records.isEmpty {
                    // Profile exists, load it
                    print("Found existing profile, loading data...")
                    self.loadUserProfile(from: records[0])
                } else {
                    // No profile found, show sign in prompt
                    self.showSignInPrompt = true
                }
            }
        }
    }
    
    private func loadUserProfile(from record: CKRecord) {
        // Load data from profile record
        if let username = record["username"] as? String {
            UserDefaults.standard.set(username, forKey: "profileUsername")
        }
        
        if let displayName = record["displayName"] as? String {
            UserDefaults.standard.set(displayName, forKey: "profileName")
        }
        
        isSignedIn = true
        
        // Now load progress data
        loadUserProgress()
    }
    
    private func loadUserProgress() {
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase
        
        let userID = CloudKitManager.shared.getUserID()
        let predicate = NSPredicate(format: "userID == %@", userID)
        let query = CKQuery(recordType: "UserProgress", predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error loading user progress: \(error)")
                return
            }
            
            if let records = records, !records.isEmpty {
                let record = records[0]
                
                // Update models with cloud data
                DispatchQueue.main.async {
                    if let level = record["level"] as? Int {
                        self.xpModel.level = level
                    }
                    
                    if let xp = record["xp"] as? Int {
                        self.xpModel.xp = xp
                    }
                    
                    if let balance = record["coinBalance"] as? Int {
                        self.currencyModel.balance = balance
                    }
                    
                    if let totalMinutes = record["totalStudyMinutes"] as? Double {
                        // Convert minutes to seconds for totalTimeStudied
                        self.timerModel.totalTimeStudied = Int(totalMinutes * 60)
                    }
                    
                    // Weekly study minutes is now handled differently, so we'll convert appropriately
                    if let dailyMinutes = record["daily_Minutes"] as? [Int] {
                        let totalWeeklyMinutes = dailyMinutes.reduce(0, +)
                        self.timerModel.weeklyStudyMinutes = totalWeeklyMinutes
                    }
                }
            }
        }
    }
    
    private func syncUserProgressToCloud() {
        // Instead of duplicating the logic here, call the CloudKitManager version
        CloudKitManager.shared.syncUserProgress(
            xpModel: xpModel,
            currencyModel: currencyModel, 
            timerModel: timerModel
        )
    }
    
    private func calculateStudyStreak() -> Int {
        // Just return the dailyStreak from timerModel directly
        return timerModel.dailyStreak
    }
    
    private func createLocalUserProfile() {
        // Create a default local profile when user skips sign-in
        UserDefaults.standard.set("Guest", forKey: "profileUsername")
        UserDefaults.standard.set("Guest", forKey: "profileName")
    }
    
    #if os(iOS)
    private func saveImageToTempLocation(image: UIImage) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".jpg")
        try? image.jpegData(compressionQuality: 0.8)?.write(to: url)
        return url
    }
    #endif
    
    // Move data loading to a separate function to defer non-critical operations
    private func loadRemainingData() {
        xpModel.loadData()
        categoriesModel.categories = categoriesModel.loadCategories()
        taskModel.loadTasks()
        currencyModel.fetchFromICloud()
        shopModel.loadData()
        civModel.updateFromBackground()
        miningModel.resumeMiningIfNeeded()
    }
}

@main
struct CosmosApp: App {
    init() {
        #if DEBUG && canImport(StoreKitTest)
        // list bundled .storekit files
        let configs = Bundle.main.paths(forResourcesOfType: "storekit", inDirectory: nil)
        print("🔍 Bundle .storekit files:", configs)

        // load your BitBytePro.storekit
        if let url = Bundle.main.url(forResource: "BitBytePro", withExtension: "storekit") {
            print("🔍 Loading StoreKit config at:", url)
            do {
                let session = try SKTestSession(configurationFileURL: url)
                session.disableDialogs = true
                session.clearTransactions()
                print("✅ StoreKitTest session started")
            } catch {
                print("⛔️ StoreKitTest session failed:", error)
            }
        } else {
            print("⛔️ .storekit file not found – check target membership")
        }
        #endif

        setupCloudKit()
    }
    
    var body: some Scene {
        WindowGroup {
            BitAppView()
                .preferredColorScheme(.dark)  // Forces everything into Dark Mode
                .onAppear {
                    // Test CloudKit specifically
                    testCloudKitAccess()
                }
                // Set minimum window size
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize) // Respects the minimum content size
        .defaultSize(width: 1000, height: 800) // Default window size on launch
        #endif
    }
    
    private func testCloudKitAccess() {
        print("🔍 CLOUDKIT TEST: Starting test...")
        
        // 1. Verify container access
        let container = CKContainer.default()
        print("🔍 CLOUDKIT TEST: Using default container: \(container.containerIdentifier ?? "unknown")")
        
        // 2. Check account status
        container.accountStatus { status, error in
            if let error = error {
                print("🔍 CLOUDKIT TEST: Account error: \(error.localizedDescription)")
            } else {
                print("🔍 CLOUDKIT TEST: Account status: \(status.rawValue) - \(status)")
                
                // 3. Test private database access
                let privateDB = container.privateCloudDatabase
                print("🔍 CLOUDKIT TEST: Got private database")
                
                // 4. Create a simple test record
                let testRecord = CKRecord(recordType: "TestRecord")
                testRecord["testValue"] = "Testing CloudKit access" as CKRecordValue
                testRecord["timestamp"] = Date() as CKRecordValue
                
                // 5. Save the test record
                privateDB.save(testRecord) { record, error in
                    if let error = error {
                        print("🔍 CLOUDKIT TEST: Error saving test record: \(error.localizedDescription)")
                        if let ckError = error as? CKError {
                            print("🔍 CLOUDKIT TEST: CKError code: \(ckError.errorCode)")
                        }
                    } else {
                        print("🔍 CLOUDKIT TEST: Successfully saved test record!")
                        
                        // 6. Fetch the test record back
                        privateDB.fetch(withRecordID: testRecord.recordID) { fetchedRecord, error in
                            if let error = error {
                                print("🔍 CLOUDKIT TEST: Error fetching test record: \(error.localizedDescription)")
                            } else if let record = fetchedRecord {
                                print("🔍 CLOUDKIT TEST: Successfully fetched test record: \(record["testValue"] ?? "no value")")
                                
                                // 7. Delete the test record to clean up
                                privateDB.delete(withRecordID: record.recordID) { _, error in
                                    if let error = error {
                                        print("🔍 CLOUDKIT TEST: Error deleting test record: \(error.localizedDescription)")
                                    } else {
                                        print("🔍 CLOUDKIT TEST: Successfully deleted test record!")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setupCloudKit() {
        print("🌩️ CloudKit initialization starting...")
        
        // Clear any potential cached references
        UserDefaults.standard.removeObject(forKey: "com.apple.cloudkit.containers")
        
        // Use the default container - don't specify a custom identifier
        let container = CKContainer.default()
        print("🌩️ Container identifier: \(container.containerIdentifier ?? "unknown")")
        
        // Check account status to verify CloudKit is working
        container.accountStatus { status, error in
            if let error = error {
                print("🌩️❌ CloudKit error: \(error.localizedDescription)")
            } else {
                print("🌩️✅ CloudKit status: \(status.rawValue)")
                
                // Initialize our shared container reference
                _ = CloudKitContainer.shared
                print("🌩️ CloudKitContainer.shared initialized")
            }
        }
        
        // Initialize key-value store
        let store = NSUbiquitousKeyValueStore.default
        store.synchronize()
        print("🌩️ Key-value store initialized")
    }
}

// Update the CloudKitContainer class to use the default container
class CloudKitContainer {
    static let shared = CloudKitContainer()
    
    let container: CKContainer
    let privateDB: CKDatabase
    
    private init() {
        // Use the default container from the entitlements file
        self.container = CKContainer.default()
        self.privateDB = container.privateCloudDatabase
        print("🌩️ CloudKitContainer initialized with: \(container.containerIdentifier ?? "unknown")")
    }
}


