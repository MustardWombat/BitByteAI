import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskModel: TaskModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var currencyModel: CurrencyModel

    @State private var showSortMenu: Bool = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    // --- Top Row: Sort Dropdown ---
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
                    }
                    
                    // --- Task List ---
                    List {
                        ForEach(taskModel.tasks.filter { task in
                            if task.isCompleted, let done = task.completedAt {
                                return Date().timeIntervalSince(done) < 86400 // hide if completed over 1 day ago
                            }
                            return true
                        }) { task in
                            HStack {
                                // Replace the static image with a button for incomplete tasks
                                if task.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Button {
                                        taskModel.completeTask(task, xpModel: xpModel, currencyModel: currencyModel)
                                    } label: {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
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
                                        // XP/Coins for incomplete tasks
                                        if !task.isCompleted {
                                            Text("+\(task.xpReward) XP, +\(task.coinReward) Coins")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                Spacer()
                                // For completed tasks, show Delete button
                                if task.isCompleted {
                                    Button(action: { taskModel.removeTask(task) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(TransparentButtonStyle())
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .padding(.vertical, 50)
                .frame(width: 800, height: 600) // Set default size to a normal rectangle
            }
            .padding(.horizontal, 20)
            .background(Color.black)
            .toolbar { // New Task button now in navigation bar
#if os(iOS)
.pickerStyle(WheelPickerStyle())
#endif
                NavigationLink(destination: TaskMakerView().environmentObject(taskModel)) {
                        Label("New Task", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
    }

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

