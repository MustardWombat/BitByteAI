import CoreML
import Foundation

class MLManager {
    static let shared = MLManager()
    
    // Different models for different prediction tasks
    private var timePredictor: MLModel?
    private var durationPredictor: MLModel?
    private var difficultyPredictor: MLModel?
    
    // Development phase tracking
    enum MLFeature: String {
        case notificationTiming
        case studyDuration
        case taskRecommendation
    }
    
    private var availableFeatures: Set<MLFeature> = []
    
    init() {
        loadModels()
    }
    
    // Load models at app start
    func loadModels() {
        // Check for bundled models first (included in app)
        if let timePredictorURL = Bundle.main.url(forResource: "NotificationTimePredictor", withExtension: "mlmodelc") {
            do {
                timePredictor = try MLModel(contentsOf: timePredictorURL)
                availableFeatures.insert(.notificationTiming)
                print("Loaded notification timing model from bundle")
            } catch {
                print("Error loading bundled time predictor: \(error)")
            }
        }
        
        // Check for other models
        if let durationPredictorURL = Bundle.main.url(forResource: "OptimalDurationModel", withExtension: "mlmodelc") {
            do {
                durationPredictor = try MLModel(contentsOf: durationPredictorURL)
                availableFeatures.insert(.studyDuration)
                print("Loaded duration model from bundle")
            } catch {
                print("Error loading bundled duration predictor: \(error)")
            }
        }
    }
    
    /// Check server for updated models
    func checkForModelUpdates() {
        let url = URL(string: "https://bitbyte.lol/api/models/latest")!
        
        URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                if let error = error {
                    print("Error downloading model: \(error)")
                }
                return
            }
            
            // Get the documents directory URL
            let documentsDirectory = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]
            
            // Create the destination URL for the downloaded file
            let destinationURL = documentsDirectory.appendingPathComponent("NotificationTimePredictor.mlmodel")
            
            // Delete the existing file if it exists
            try? FileManager.default.removeItem(at: destinationURL)
            
            do {
                // Copy the downloaded file to the destination
                try FileManager.default.copyItem(at: localURL, to: destinationURL)
                
                // Notify about successful update
                DispatchQueue.main.async {
                    // Update our loaded models
                    self.loadModels()
                    
                    // Post notification so UI can update
                    NotificationCenter.default.post(
                        name: Notification.Name("MLModelUpdated"),
                        object: nil
                    )
                }
            } catch {
                print("Error saving downloaded model: \(error)")
            }
        }.resume()
    }
    
    // Check if a feature is available
    func isFeatureAvailable(_ feature: MLFeature) -> Bool {
        return availableFeatures.contains(feature)
    }
    
    // Different prediction methods for different features
    func predictOptimalNotificationTime(dayOfWeek: Int, currentHour: Int) -> DateComponents? {
        guard isFeatureAvailable(.notificationTiming), let timePredictor = timePredictor else {
            return nil
        }
        
        // Create prediction input
        let isWeekend = (dayOfWeek == 1 || dayOfWeek == 7) ? 1 : 0
        
        do {
            // Create input dictionary
            let inputFeatures: [String: MLFeatureValue] = [
                "dayOfWeek": MLFeatureValue(int64: Int64(dayOfWeek)),
                "hour": MLFeatureValue(int64: Int64(currentHour)),
                "isWeekend": MLFeatureValue(int64: Int64(isWeekend)),
                "duration": MLFeatureValue(double: 600.0),
                "engagement": MLFeatureValue(double: 0.8)
            ]
            
            let input = try MLDictionaryFeatureProvider(dictionary: inputFeatures)
            let prediction = try timePredictor.prediction(from: input)
            
            if let hourValue = prediction.featureValue(for: "optimalHour")?.int64Value {
                var components = DateComponents()
                components.hour = Int(hourValue)
                components.minute = 0
                return components
            }
        } catch {
            print("Prediction error: \(error)")
        }
        
        return nil
    }
    
    // Add a method to get the data collection status
    func getDataCollectionStatus() -> (sessionsCollected: Int, sessionsNeeded: Int) {
        let tracker = ProductivityTracker.shared
        let collected = tracker.productivitySessions.count
        let needed = max(0, tracker.minSessionsForAI - collected)
        return (collected, needed)
    }
}
