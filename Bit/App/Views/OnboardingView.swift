import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @State private var selection: Int = 0
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var categoriesViewModel = CategoriesViewModel()
    @State private var showCategoryCreationOverlay = false
    @State private var presetCategoryName = ""
    @State private var presetCategoryColor = Color.blue
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
                
                // Page 3: Sign In
                SignInPromptView(
                    onSignIn: {
                        onSignIn()
                        withAnimation { selection = 3 }
                    },
                    onSkip: {
                        onSkip()
                        withAnimation { selection = 3 }
                    }
                )
                .tag(2)
                
                // Page 4: Create First Category
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
                        withAnimation { selection = 4 }
                    }
                    .foregroundColor(.gray)
                }
                .tag(3)
                .padding()
                
                // Page 5: Welcome & Upgrade
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
                        // Handle upgrade
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
                .tag(4)
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
                        withAnimation { selection = 4 }
                    },
                    onDeleteCategory: { _ in },
                    onCancel: {
                        showCategoryCreationOverlay = false
                    }
                )
            }
        }
    }
    
    private func openCategoryCreation(_ name: String, color: Color) {
        presetCategoryName = name
        presetCategoryColor = color
        showCategoryCreationOverlay = true
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
    }
}
