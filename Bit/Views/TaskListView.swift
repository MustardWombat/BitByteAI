import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskModel: TaskModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var currencyModel: CurrencyModel

    @State private var newTaskTitle: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("New Task", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    let trimmed = newTaskTitle.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    taskModel.addTask(title: trimmed)
                    newTaskTitle = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding(.top, 20)

            List {
                ForEach(taskModel.tasks) { task in
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .strikethrough(task.isCompleted)
                                .foregroundColor(task.isCompleted ? .gray : .white)
                            if !task.isCompleted {
                                Text("+\(task.xpReward) XP, +\(task.coinReward) Coins")
                                    .font(.caption)
                                    .foregroundColor(.orange)
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
    }
}
