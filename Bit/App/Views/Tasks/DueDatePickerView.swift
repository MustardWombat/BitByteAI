import SwiftUI

struct DueDatePickerView: View {
    @Binding var selectedDate: Date?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                Button("Clear Date") {
                    selectedDate = nil
                }
                .foregroundColor(.red)
                Spacer()
            }
            .navigationTitle("Choose Due Date")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    DueDatePickerView(selectedDate: .constant(Date()), isPresented: .constant(true))
}
#endif
