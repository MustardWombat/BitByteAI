import SwiftUI

struct CategorySelectionOverlay: View {
    @Binding var categories: [Category]  // updated: changed to a binding for mutability
    @Binding var selected: Category?
    @Binding var isPresented: Bool
    @State private var showCategoryCreationOverlay = false
    @State private var categoryForEditing: Category? = nil  // To track category being edited.
    
    @AppStorage("hasSubscription") private var isPro: Bool = false
    @State private var showProSheet = false
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("Select a Category")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()

                List {
                    ForEach(categories) { category in
                        HStack {
                            Circle()
                                .fill(category.displayColor)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                            Spacer()
                            Text("\(category.weeklyGoalMinutes) min goal")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if selected?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selected = category
                            isPresented = false
                        }
                        .onLongPressGesture {
                            categoryForEditing = category
                            showCategoryCreationOverlay = true
                        }
                        .listRowBackground(Color.black)
                        .foregroundColor(.white)
                    }
                    Button("Create New Category") {
                        if !isPro && categories.count >= 3 {
                            showProSheet = true
                        } else {
                            categoryForEditing = nil
                            showCategoryCreationOverlay = true
                        }
                    }
                    .foregroundColor(.blue)
                    .listRowBackground(Color.black)
                }
                .background(Color.black)
                .foregroundColor(.white)
                .frame(maxHeight: .infinity)
            }
            
            VStack {
                HStack {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                    .font(.headline)
                    .padding([.top, .leading], 20)
                    Spacer()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showCategoryCreationOverlay) {
            CategoryCreationOverlay(
                isPresented: $showCategoryCreationOverlay,
                category: categoryForEditing,
                onSaveCategory: { name, goal, color, editingCategory in
                    if let editingCategory = editingCategory {
                        editingCategory.name = name
                        editingCategory.weeklyGoalMinutes = goal
                        editingCategory.colorHex = color.toHex()
                    } else {
                        let newCategory = Category(name: name, weeklyGoalMinutes: goal, colorHex: color.toHex())
                        categories.append(newCategory)
                    }
                },
                onDeleteCategory: { category in
                    if let index = categories.firstIndex(where: { $0.id == category.id }) {
                        categories.remove(at: index)
                    }
                },
                onCancel: {
                    showCategoryCreationOverlay = false
                }
            )
        }
        .sheet(isPresented: $showProSheet) {
            SubscriptionConfirmationView(
                isPresented: $showProSheet,
                subscriptionManager: subscriptionManager
            )
        }
    }
}
