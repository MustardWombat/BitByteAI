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
    cancelReminders()
    let center = UNUserNotificationCenter.current()
    for (index, time) in reminderTimes.enumerated() {
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
                print("Error scheduling reminder \(index): \(error)")
            } else {
                print("Reminder \(index) scheduled.")
            }
        }
    }
}

func sendDebugNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Debug Notification"
    content.body = "This is a test notification."
    content.sound = .default
    
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    
    let request = UNNotificationRequest(identifier: "debugNotification", content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Error scheduling debug notification: \(error)")
        } else {
            print("Debug notification scheduled.")
        }
    }
}
