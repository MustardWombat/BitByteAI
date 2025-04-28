import SwiftUI

struct CategorySelectionOverlay: View {
    let categories: [Category]
    @Binding var selected: Category?
    @Binding var isPresented: Bool

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
                }
            }

            Button("Add New Category") {
                isPresented = false
                // Trigger category adder view
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
}
