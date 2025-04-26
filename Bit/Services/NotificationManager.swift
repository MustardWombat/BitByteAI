import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    var reminderTimes: [DateComponents] = {
        var times = [DateComponents]()
        // Sample reminder at 9:00 AM.
        var morning = DateComponents()
        morning.hour = 9
        morning.minute = 0
        times.append(morning)
        // Sample reminder at 6:00 PM.
        var evening = DateComponents()
        evening.hour = 18
        evening.minute = 0
        times.append(evening)
        return times
    }()
    
    func cancelReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            } else if !granted {
                print("User did not grant notification permissions.")
            } else {
                print("Notifications authorized!")
            }
        }
    }
    
    func scheduleReminders() {
        print("DEBUG: scheduleReminders called")
        cancelReminders()
        let center = UNUserNotificationCenter.current()
        for (index, time) in reminderTimes.enumerated() {
            print("DEBUG: Preparing reminder \(index) with time components: \(time)")
            
            let content = UNMutableNotificationContent()
            content.title = "Study Reminder"
            content.body = "You haven't studied yet today. Time to focus!"
            content.sound = .default
            
            // Log the time components for debugging
            print("Scheduling reminder \(index) for time components: \(time)")
            
            var triggerDate = time
            triggerDate.calendar = Calendar.current
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
            
            let request = UNNotificationRequest(identifier: "studyReminder\(index)", content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("DEBUG: Error scheduling reminder \(index) with trigger \(trigger): \(error)")
                } else {
                    print("DEBUG: Reminder \(index) scheduled with trigger \(trigger)")
                }
            }
        }
    }
    
    // Added updateReminders method
    func updateReminders() {
        scheduleReminders()
    }
    
    func sendDebugNotification() {
        print("DEBUG: sendDebugNotification called")
        #if os(macOS)
        print("DEBUG: Running on macOS")
        #else
        print("DEBUG: Running on iOS")
        #endif
        
        let content = UNMutableNotificationContent()
        content.title = "Debug Notification"
        content.body = "This is a test notification."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let request = UNNotificationRequest(identifier: "debugNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Error scheduling debug notification with trigger \(trigger): \(error)")
            } else {
                print("DEBUG: Debug notification scheduled with trigger \(trigger)")
            }
        }
    }
    
    // Allow notifications to be shown while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
