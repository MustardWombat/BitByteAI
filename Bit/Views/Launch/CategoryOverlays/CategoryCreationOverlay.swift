import SwiftUI

struct CategoryCreationOverlay: View {
    @Binding var isPresented: Bool
    var category: Category? = nil  // Optional category to edit; nil means create new.

    @State private var categoryName: String = ""
    @State private var selectedHours: Int = 1  // Default to 1 hour
    @State private var selectedMinutes: Int = 0
    @State private var selectedColor: Color = .blue
    @State private var showDeleteAlert = false
    
    var onSaveCategory: (String, Int, Color, Category?) -> Void = { _, _, _, _ in }
    var onDeleteCategory: (Category) -> Void
    var onCancel: () -> Void = {}

    // Add a default initializer to ensure onDeleteCategory is provided
    init(isPresented: Binding<Bool>, category: Category? = nil, 
         onSaveCategory: @escaping (String, Int, Color, Category?) -> Void = { _, _, _, _ in },
         onDeleteCategory: @escaping (Category) -> Void,
         onCancel: @escaping () -> Void = {}) {
        self._isPresented = isPresented
        self.category = category
        self.onSaveCategory = onSaveCategory
        self.onDeleteCategory = onDeleteCategory
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(category == nil ? "Create Category" : "Edit Category")
                .font(.headline)

            TextField("Name", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            VStack {
                Text("Weekly Goal")
                    .font(.subheadline)

                HStack {
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(0..<24) { hour in
                            Text("\(hour) h").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: 100)

                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(0..<60) { minute in
                            Text("\(minute) m").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: 100)
                }
            }

            VStack {
                Text("Color")
                    .font(.subheadline)
                if category == nil {
                    ColorPicker("Select Color", selection: $selectedColor)
                        .padding()
                } else {
                    // Allow editing of color for existing categories.
                    ColorPicker("Select Color", selection: $selectedColor)
                        .padding()
                }
            }

            HStack {
                Button("Save") {
                    let totalMinutes = (selectedHours * 60) + selectedMinutes
                    if !categoryName.isEmpty {
                        onSaveCategory(categoryName, totalMinutes, selectedColor, category)
                        isPresented = false
                    } else {
                        print("Category name is empty. Save aborted.")
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Cancel") {
                    onCancel()
                    isPresented = false
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // Delete button only appears when editing an existing category
            if category != nil {
                Button("Delete Category") {
                    showDeleteAlert = true
                }
                .padding()
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 10)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Category"),
                message: Text("Are you sure you want to delete '\(categoryName)'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let categoryToDelete = category {
                        print("Deleting category: \(categoryToDelete.name)")
                        onDeleteCategory(categoryToDelete)
                        isPresented = false
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            if let cat = category {
                categoryName = cat.name
                let total = cat.weeklyGoalMinutes
                selectedHours = total / 60
                selectedMinutes = total % 60
                selectedColor = cat.displayColor
            }
        }
    }
}

