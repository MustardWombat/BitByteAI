import SwiftUI
import AuthenticationServices
import UserNotifications

struct OnboardingView: View {
    @State private var selection: Int = 0
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showCategoryCreationOverlay = false
    @State private var showTaskCreationOverlay = false
    @State private var presetCategoryName = ""
    @State private var presetCategoryColor = Color.blue
    @State private var showSubscriptionOverlay = false

    @State private var notificationRequested = false
    @State private var notificationGranted = false

    // New @AppStorage properties for reminder times
    @AppStorage("reminderTime1") private var reminderTime1Interval: Double = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
    @AppStorage("reminderTime2") private var reminderTime2Interval: Double = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970

    // @State properties for UI selection of reminder times
    @State private var onboardingTime1 = Date(timeIntervalSince1970: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970)
    @State private var onboardingTime2 = Date(timeIntervalSince1970: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())?.timeIntervalSince1970 ?? Date().timeIntervalSince1970)

    // Use environment objects instead of creating new ones
    @EnvironmentObject var categoriesViewModel: CategoriesViewModel
    @EnvironmentObject var taskModel: TaskModel

    var onSignIn: () -> Void
    var onSkip: () -> Void
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                // Page 1: Procrastination Facts
                VStack(spacing: 30) {
                    Text("Did You Know?")
                        .font(.largeTitle)
                        .bold()

                    VStack(spacing: 20) {
                        Text("📊 95% of people admit to procrastinating")
                            .font(.title2)
                            .multilineTextAlignment(.center)

                        Text("⏰ The average person wastes 2+ hours daily due to poor organization")
                            .font(.title2)
                            .multilineTextAlignment(.center)

                        Text("🎯 Students who use productivity apps score 23% higher on tests")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    Button("Continue") {
                        withAnimation { selection = 1 }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .tag(0)
                .padding()

                // Page 2: App Benefits
                VStack(spacing: 30) {
                    Text("BitByte Results")
                        .font(.largeTitle)
                        .bold()

                    VStack(spacing: 20) {
                        Text("🚀 Users report 40% increased productivity")
                            .font(.title2)
                            .multilineTextAlignment(.center)

                        Text("📚 Students improved test scores by 18% on average")
                            .font(.title2)
                            .multilineTextAlignment(.center)

                        Text("⭐ 4.8/5 stars with over 10,000 reviews")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    Button("Amazing! Let's Start") {
                        withAnimation { selection = 2 }
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .tag(1)
                .padding()

                // Page 3: Sign In with Apple
                VStack(spacing: 30) {
                    Text("Sign In With Apple")
                        .font(.largeTitle)
                        .bold()
                    Text("To continue, please sign in with your Apple ID. Signing in is optional and only required for syncing and social features.")
                        .multilineTextAlignment(.center)
                        .padding()
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            // Configure request if needed
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(_):
                                onSignIn()
                                withAnimation { selection = 3 }
                            case .failure(_):
                                // Optionally show an error
                                break
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    Button("Continue without Signing In") {
                        onSkip()
                        withAnimation { selection = 3 }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .tag(2)
                .padding()
                
                // New Page 4: Notification Permission
                VStack(spacing: 30) {
                    Text("Stay On Track with Reminders")
                        .font(.largeTitle)
                        .bold()
                    Text("Enable notifications so we can remind you of tasks and keep you motivated.")
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Enable Notifications") {
                        requestNotificationPermission()
                    }
                    .padding()
                    .background(notificationGranted ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(notificationRequested)
                    if notificationRequested {
                        Button("Continue") {
                            withAnimation { selection = 4 }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .tag(3)
                .padding()

                // New Page 5: Reminder Time Selection
                VStack(spacing: 30) {
                    Text("When do you like to study?")
                        .font(.largeTitle)
                        .bold()
                    Text("Set two daily times and we'll remind you to focus at your preferred moments.")
                        .multilineTextAlignment(.center)
                        .padding()
                    VStack(spacing: 20) {
                        DatePicker("First reminder time", selection: $onboardingTime1, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        DatePicker("Second reminder time", selection: $onboardingTime2, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    Button("Continue") {
                        reminderTime1Interval = onboardingTime1.timeIntervalSince1970
                        reminderTime2Interval = onboardingTime2.timeIntervalSince1970
                        scheduleStudyReminders()
                        withAnimation { selection = 5 }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .tag(4)
                .padding()
                .onAppear {
                    onboardingTime1 = Date(timeIntervalSince1970: reminderTime1Interval)
                    onboardingTime2 = Date(timeIntervalSince1970: reminderTime2Interval)
                }

                // Updated Page 6: Create First Category (tag incremented from 4 to 5)
                VStack(spacing: 30) {
                    Text("Create Your First Category")
                        .font(.largeTitle)
                        .bold()

                    Text("Categories help organize your tasks and goals. What would you like to focus on first?")
                        .multilineTextAlignment(.center)
                        .padding()

                    VStack(spacing: 15) {
                        Button("📚 School & Studies") {
                            openCategoryCreation("School & Studies", color: Color(hex: "#4D96FF"))
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("💼 Work & Career") {
                            openCategoryCreation("Work & Career", color: Color(hex: "#F97316"))
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("🏃 Health & Fitness") {
                            openCategoryCreation("Health & Fitness", color: Color(hex: "#6BCB77"))
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("🎨 Personal Projects") {
                            openCategoryCreation("Personal Projects", color: Color(hex: "#A78BFA"))
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("✏️ Create Custom Category") {
                            openCategoryCreation("", color: .blue)
                        }
                        .buttonStyle(CategoryButtonStyle())
                        .foregroundColor(.orange)
                    }

                    Button("Skip for now") {
                        withAnimation { selection = 7 }
                    }
                    .foregroundColor(.gray)
                }
                .tag(5)
                .padding()

                // Updated Page 7: Create First Task (tag incremented from 5 to 6)
                VStack(spacing: 30) {
                    Text("Add Your First Task")
                        .font(.largeTitle)
                        .bold()

                    Text("Tasks help you break down your goals into actionable steps. Let's create your first one!")
                        .multilineTextAlignment(.center)
                        .padding()

                    VStack(spacing: 15) {
                        Button("📖 Read a chapter") {
                            createPresetTask("Read a chapter", difficulty: 2)
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("✍️ Complete assignment") {
                            createPresetTask("Complete assignment", difficulty: 4)
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("🏋️ Exercise for 30 minutes") {
                            createPresetTask("Exercise for 30 minutes", difficulty: 3)
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("📝 Write project proposal") {
                            createPresetTask("Write project proposal", difficulty: 4)
                        }
                        .buttonStyle(CategoryButtonStyle())

                        Button("✏️ Create Custom Task") {
                            showTaskCreationOverlay = true
                        }
                        .buttonStyle(CategoryButtonStyle())
                        .foregroundColor(.orange)
                    }

                    Button("Skip for now") {
                        withAnimation { selection = 7 }
                    }
                    .foregroundColor(.gray)
                }
                .tag(6)
                .padding()

                // Updated Page 8: Welcome & Upgrade (tag incremented from 6 to 7)
                VStack(spacing: 30) {
                    Text("Welcome to BitByte! 🎉")
                        .font(.largeTitle)
                        .bold()

                    Text("You're all set to boost your productivity!")
                        .font(.title2)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 15) {
                        Text("✨ Unlock BitByte Pro for:")
                            .font(.headline)
                            .bold()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Unlimited categories and tasks")
                            Text("• Advanced analytics and insights")
                            Text("• Custom themes and widgets")
                            Text("• Priority customer support")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button("Upgrade to Pro") {
                        showSubscriptionOverlay = true
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("Start Using BitByte") {
                        onComplete()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .tag(7)
                .padding()
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .task {
                await subscriptionManager.loadProduct()
            }

            // Category Creation Overlay
            if showCategoryCreationOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showCategoryCreationOverlay = false
                    }

                CategoryCreationOverlay(
                    isPresented: $showCategoryCreationOverlay,
                    category: nil,
                    initialName: presetCategoryName,
                    initialColor: presetCategoryColor,
                    onSaveCategory: { name, goalMinutes, color, _ in
                        let newCategory = Category(name: name, weeklyGoalMinutes: goalMinutes, colorHex: color.toHex())
                        categoriesViewModel.categories.append(newCategory)
                        withAnimation { selection = 6 }
                    },
                    onDeleteCategory: { _ in },
                    onCancel: {
                        showCategoryCreationOverlay = false
                    }
                )
            }

            // Task Creation Overlay
            if showTaskCreationOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showTaskCreationOverlay = false
                    }

                TaskCreationOverlay(
                    isPresented: $showTaskCreationOverlay
                )
                .environmentObject(taskModel)
                .onDisappear {
                    // Move to next screen when task is created
                    if !showTaskCreationOverlay {
                        withAnimation { selection = 7 }
                    }
                }
            }

            if showSubscriptionOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { showSubscriptionOverlay = false }
                SubscriptionConfirmationView(
                    isPresented: $showSubscriptionOverlay,
                    subscriptionManager: subscriptionManager
                )
                .frame(maxWidth: 400)
                .padding()
                .transition(.move(edge: .bottom))
                .zIndex(100)
            }
        }
    }

    private func openCategoryCreation(_ name: String, color: Color) {
        presetCategoryName = name
        presetCategoryColor = color
        showCategoryCreationOverlay = true
    }

    private func createPresetTask(_ title: String, difficulty: Int) {
        // Use the actual TaskModel functionality
        taskModel.addTask(title: title, difficulty: difficulty)
        withAnimation { selection = 7 }
    }

    private func requestNotificationPermission() {
        notificationRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationGranted = granted
            }
        }
    }

    private func scheduleStudyReminders() {
        let comp1 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime1Interval))
        let comp2 = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSince1970: reminderTime2Interval))
        let notificationManager = NotificationManager.shared
        notificationManager.reminderTimes = [comp1, comp2]
        notificationManager.updateReminders()
    }
}

struct CategoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onSignIn: {}, onSkip: {}, onComplete: {})
            .environmentObject(CategoriesViewModel())
            .environmentObject(TaskModel())
    }
}
