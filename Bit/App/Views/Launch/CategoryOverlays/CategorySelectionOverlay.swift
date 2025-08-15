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
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack {
                Text("Select a Category")
                    .font(.headline)
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
                }
                .frame(maxHeight: .infinity)

                Button("Close") {
                    isPresented = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(radius: 10)
            .padding(.horizontal, 16)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
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

