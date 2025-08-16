import SwiftUI

struct TaskCreationOverlay: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var taskModel: TaskModel
    
    @State private var title: String = ""
    @State private var difficulty: Int = 3
    @State private var dueDate: Date? = nil
    @State private var showDueDatePicker: Bool = false
    
    var onSave: () -> Void = {}
    var onCancel: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            NavigationView {
                VStack(spacing: 24) {
                    TextField("Task Title", text: $title)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.subheadline)
                        HStack {
                            ForEach(1...5, id: \.self) { level in
                                Button(action: { difficulty = level }) {
                                    Image(systemName: level <= difficulty ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 24))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Due Date")
                            .font(.subheadline)
                        Button(action: { showDueDatePicker = true }) {
                            HStack {
                                if let due = dueDate {
                                    Text(due, style: .date)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Button(action: { dueDate = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Text("Set Due Date")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding()
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding([.horizontal, .top])
                .navigationTitle("Create Task")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = title.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { return }
                            taskModel.addTask(title: trimmed, difficulty: difficulty, dueDate: dueDate)
                            onSave()
                            isPresented = false
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            onCancel()
                            isPresented = false
                        }
                        .foregroundColor(.red)
                    }
                }
                .sheet(isPresented: $showDueDatePicker) {
                    DueDatePickerView(selectedDate: $dueDate, isPresented: $showDueDatePicker)
                }
            }
        }
    }
}
