import Foundation

// Note: CreateML is only available for macOS development, not for runtime in iOS apps
#if os(macOS)
import CreateML
#endif

class NotificationModelTrainer {
    static let shared = NotificationModelTrainer()
    
    func trainModel(from sessions: [ProductivityTracker.ProductivitySession]) -> URL? {
        #if os(macOS)
        // This code only runs when compiling for macOS
        return trainModelWithCreateML(from: sessions)
        #else
        // For iOS, we'll use a simpler approach
        return trainModelSimple(from: sessions)
        #endif
    }
    
    #if os(macOS)
    private func trainModelWithCreateML(from sessions: [ProductivityTracker.ProductivitySession]) -> URL? {
        // Prepare training data in the correct format
        var dayOfWeeks: [Int] = []
        var hours: [Int] = []
        var durations: [Double] = []
        var engagements: [Double] = []
        var targetHours: [Int] = []
        
        for session in sessions {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: session.timestamp)
            
            dayOfWeeks.append(session.dayOfWeek)
            hours.append(hour)
            durations.append(Double(session.duration))
            engagements.append(Double(session.engagement))
            
            // Target is one hour before productive time
            targetHours.append((hour - 1 + 24) % 24)
        }
        
        // Create a proper dictionary for CreateML
        let dataDict: [String: MLDataValueConvertible] = [
            "dayOfWeek": dayOfWeeks,
            "hour": hours,
            "duration": durations,
            "engagement": engagements,
            "optimalHour": targetHours
        ]
        
        do {
            let dataTable = try MLDataTable(dictionary: dataDict)
            
            // Check if we have enough data
            if dataTable.rows.count < 10 {
                print("Not enough data to train model")
                return nil
            }
            
            let regressor = try MLRegressor(trainingData: dataTable, targetColumn: "optimalHour")
            
            // Save the model to a file
            let modelName = "NotificationTimePredictor"
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                           in: .userDomainMask).first!
            let modelURL = documentsDirectory.appendingPathComponent("\(modelName).mlmodel")
            
            // try regressor.write(to: modelURL, metadata: <#MLModelMetadata?#>)
            return modelURL
        } catch {
            print("Error training model: \(error)")
            return nil
        }
    }
    #endif
    
    // Simple training approach that works on iOS
    private func trainModelSimple(from sessions: [ProductivityTracker.ProductivitySession]) -> URL? {
        // This is a placeholder for a simpler training approach
        // In a real app, you would generate a Core ML model file during development,
        // not at runtime, and include it in your app bundle
        
        print("Simple model training - this is just a placeholder")
        
        return nil // Return nil as we can't actually create a model file at runtime on iOS
    }
}
