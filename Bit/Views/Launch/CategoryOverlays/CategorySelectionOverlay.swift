import SwiftUI

struct CategorySelectionOverlay: View {
    @Binding var categories: [Category]  // updated: changed to a binding for mutability
    @Binding var selected: Category?
    @Binding var isPresented: Bool
    @State private var showCategoryCreationOverlay = false
    @State private var categoryForEditing: Category? = nil  // To track category being edited.

    var body: some View {
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
                    .onLongPressGesture {  // Long press to edit the category.
                        categoryForEditing = category
                        showCategoryCreationOverlay = true
                    }
                }
                Button("Create New Category") {
                    categoryForEditing = nil
                    showCategoryCreationOverlay = true
                }
                .foregroundColor(.blue)
            }

            Button("Close") {
                isPresented = false
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 10)
        .sheet(isPresented: $showCategoryCreationOverlay) {
            CategoryCreationOverlay(
                isPresented: $showCategoryCreationOverlay,
                category: categoryForEditing,  // Pass the selected category to edit, or nil for creation.
                onSaveCategory: { name, goal, color, editingCategory in
                    if let editingCategory = editingCategory {
                        // Update an existing category.
                        editingCategory.name = name
                        editingCategory.weeklyGoalMinutes = goal
                        editingCategory.colorHex = color.toHex()
                    } else {
                        // Create a new category and add it to the list.
                        let newCategory = Category(name: name, weeklyGoalMinutes: goal, colorHex: color.toHex())
                        categories.append(newCategory)
                    }
                },
                onDeleteCategory: { category in
                    // Implement actual category deletion here
                    if let index = categories.firstIndex(where: { $0.id == category.id }) {
                        categories.remove(at: index)
                    }
                },
                onCancel: {
                    showCategoryCreationOverlay = false
                }
            )
        }
    }
}
