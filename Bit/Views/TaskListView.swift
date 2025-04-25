import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskModel: TaskModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var currencyModel: CurrencyModel

    @State private var showNewTaskSheet: Bool = false
    @State private var showSortMenu: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // --- Top Row: Sort Dropdown + New Task Button ---
            HStack {
                // Sort Dropdown
                Menu {
                    Button {
                        taskModel.sortOption = .dueDate
                    } label: {
                        Label("Due Date", systemImage: "calendar")
                    }
                    Button {
                        taskModel.sortOption = .difficulty
                    } label: {
                        Label("Difficulty", systemImage: "flame.fill")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sortIcon(for: taskModel.sortOption))
                            .foregroundColor(.green)
                        Text(sortLabel(for: taskModel.sortOption))
                            .foregroundColor(.green)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.top, 20)

                Spacer()

                Button(action: { showNewTaskSheet = true }) {
                    Label("New Task", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding(.top, 20)
            }

            // --- Task List ---
            List {
                ForEach(taskModel.tasks) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .gray : .white)
                            HStack(spacing: 8) {
                                // Difficulty
                                Text("⭐️\(task.difficulty)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                // Due Date (custom display)
                                if let due = task.dueDate {
                                    Text(dueDateDisplay(due))
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                // XP/Coins
                                if !task.isCompleted {
                                    Text("+\(task.xpReward) XP, +\(task.coinReward) Coins")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        Spacer()
                        if !task.isCompleted {
                            Button("Complete") {
                                taskModel.completeTask(task, xpModel: xpModel, currencyModel: currencyModel)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(.blue)
                        } else {
                            Button(action: {
                                taskModel.removeTask(task)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
        .padding(.horizontal, 20)
        .background(Color.black)
        .sheet(isPresented: $showNewTaskSheet) {
            NewTaskSheet(isPresented: $showNewTaskSheet)
                .environmentObject(taskModel)
        }
    }

    // Helper for due date display
    func dueDateDisplay(_ due: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: due)
        let components = calendar.dateComponents([.day], from: today, to: dueDay)
        guard let days = components.day else {
            return due.formatted(date: .abbreviated, time: .omitted)
        }
        if days == 0 {
            return "Due Today"
        } else if days > 0 && days <= 7 {
            return days == 1 ? "1 day left" : "\(days) days left"
        } else if days < 0 && days >= -7 {
            return days == -1 ? "1 day ago" : "\(-days) days ago"
        } else {
            return due.formatted(date: .abbreviated, time: .omitted)
        }
    }

    func sortLabel(for option: TaskSortOption) -> String {
        switch option {
        case .dueDate: return "Due Date"
        case .difficulty: return "Difficulty"
        default: return "Sort"
        }
    }

    func sortIcon(for option: TaskSortOption) -> String {
        switch option {
        case .dueDate: return "calendar"
        case .difficulty: return "flame.fill"
        default: return "arrow.up.arrow.down"
        }
    }
}

// --- Sort Button View ---
struct SortButton: View {
    let label: String
    let isSelected: Bool
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundColor(isSelected ? .green : .gray)
                Text(label)
                    .font(.caption)
                    .foregroundColor(isSelected ? .green : .gray)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(isSelected ? Color.green.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NewTaskSheet: View {
    @EnvironmentObject var taskModel: TaskModel
    @Binding var isPresented: Bool

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
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        taskModel.addTask(title: trimmed, difficulty: difficulty, dueDate: dueDate)
                        isPresented = false
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
