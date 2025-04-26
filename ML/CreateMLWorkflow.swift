/*
CREATE ML WORKFLOW GUIDE
========================

1. DATA PREPARATION
------------------
- Create a CSV file with these columns:
  * dayOfWeek (1-7, where 1 is Sunday)
  * hour (0-23, the hour of the productive session)
  * isWeekend (0 or 1, derived from dayOfWeek)
  * duration (in seconds)
  * engagement (0.0-1.0)
  * optimalHour (target column: typically 1 hour before productive session)

2. IN CREATE ML APP
------------------
- Open Create ML app
- Create New Project
- Select "Tabular Regression"
- Import your CSV file
- Set target column to "optimalHour"
- Choose algorithm: Boosted Tree (recommended) or Random Forest
- Configure parameters:
  * Maximum depth: 6 (start with this)
  * Minimum child weight: 0.1
  * Number of boosting iterations: 100
- Set validation method (recommended: 20% validation split)
- Train model

3. EVALUATE RESULTS
------------------
- Check the RMSE (Root Mean Square Error) - lower is better
- Review validation results
- If needed, adjust parameters and retrain

4. EXPORT THE MODEL
------------------
- Export as .mlmodel file
- Add to your Xcode project
- Xcode will generate Swift code for model interface
*/

// EXAMPLE DATA GENERATION CODE FOR TESTING
// In Terminal, run: swift CreateMLWorkflow.swift > training_data.csv
func generateSampleTrainingData() {
    // Header row
    print("dayOfWeek,hour,isWeekend,duration,engagement,optimalHour")
    
    // Generate 200 sample data points
    for _ in 1...200 {
        let dayOfWeek = Int.random(in: 1...7)
        let isWeekend = (dayOfWeek == 1 || dayOfWeek == 7) ? 1 : 0
        
        // People tend to be productive at different times on weekends vs weekdays
        let baseHour = isWeekend == 1 ? 14 : 10 // Weekend: afternoon, Weekday: morning
        let hourVariation = Int.random(in: -3...3)
        let hour = max(0, min(23, baseHour + hourVariation))
        
        // Duration in seconds (5-30 minutes)
        let duration = Double.random(in: 300...1800)
        
        // Engagement level
        let engagement = Double.random(in: 0.5...1.0)
        
        // Target value: optimal notification time (1 hour before productive time)
        let optimalHour = (hour - 1 + 24) % 24
        
        print("\(dayOfWeek),\(hour),\(isWeekend),\(duration),\(engagement),\(optimalHour)")
    }
}
