import SwiftUI

struct TaskMakerView: View {
    @EnvironmentObject var taskModel: TaskModel
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var difficulty: Int = 3
    @State private var dueDate: Date? = nil
    @State private var showDueDatePicker: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(1...5, id: \.self) { level in
                            Text("⭐️\(level)").tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    HStack {
                        Text("Due Date")
                        Spacer()
                        if let due = dueDate {
                            Text(due, style: .date)
                                .foregroundColor(.orange)
                            Button(action: { dueDate = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        } else {
                            Button("Set") { showDueDatePicker = true }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        taskModel.addTask(title: trimmed, difficulty: difficulty, dueDate: dueDate)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showDueDatePicker) {
                VStack {
                    DatePicker(
                        "Due Date",
                        selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    Button("Done") { showDueDatePicker = false }
                        .padding()
                }
            }
        }
    }
}
