//  ContentView.swift
//  BitByteAI
//
//  Last edited 05/08/25.
//

import SwiftUI
import WidgetKit
import CloudKit

// Add this at the top of the file - properly configured CloudKit manager
class CloudKitContainer {
    static let shared = CloudKitContainer()
    
    // Use your specific container ID instead of default
    let container: CKContainer
    let privateDB: CKDatabase
    
    private init() {
        // Use specific container identifier for the new record types
        container = CKContainer(identifier: "iCloud.com.yourcompany.BitByteAI")  // Replace with your actual container ID
        privateDB = container.privateCloudDatabase
        
        // Check container availability at startup
        checkContainerAvailability()
    }
    
    func checkContainerAvailability() {
        container.accountStatus { [weak self] status, error in
            if let error = error {
                print("CloudKit container error: \(error.localizedDescription)")
                return
            }
            
            switch status {
            case .available:
                print("CloudKit container available")
            case .noAccount:
                print("No iCloud account found")
            case .restricted:
                print("iCloud account is restricted")
            case .couldNotDetermine:
                print("Could not determine iCloud account status")
            case .temporarilyUnavailable:
                print("iCloud account temporarily unavailable")
            @unknown default:
                print("Unknown iCloud account status")
            }
        }
    }
}

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
        // Replace default container with our explicit container
        let privateDB = CloudKitContainer.shared.privateDB
        
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
        // Replace default container with our explicit container
        let privateDB = CloudKitContainer.shared.privateDB
        
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
    // Initialize CloudKit container at app launch
    init() {
        // This triggers CloudKitContainer initialization
        _ = CloudKitContainer.shared
    }
    
    var body: some Scene {
        WindowGroup {
            BitAppView()
                .preferredColorScheme(.dark)  // Forces everything into Dark Mode
                .onAppear {
                    NSUbiquitousKeyValueStore.default.synchronize()
                }
        }
    }
}


