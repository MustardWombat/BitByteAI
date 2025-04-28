import SwiftUI

struct CategoryAdderView: View {
    @State private var categoryName: String = ""
    @State private var weeklyGoalMinutes: String = ""
    var onAddCategory: (String, Int) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Category")
                .font(.headline)

            TextField("Category Name", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Weekly Goal (minutes)", text: $weeklyGoalMinutes)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Add") {
                    if let minutes = Int(weeklyGoalMinutes), !categoryName.isEmpty {
                        onAddCategory(categoryName, minutes)
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Cancel") {
                    onCancel()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
