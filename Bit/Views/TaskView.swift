import SwiftUI

struct TaskView: View {
    @EnvironmentObject var taskModel: TaskModel

    var body: some View {
        VStack {
            Text("Task Manager")
                .font(.largeTitle)
                .padding(.top, 16)

            List {
                ForEach(taskModel.tasks) { task in
                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.headline)
                        if let due = task.dueDate {
                            Text(due, style: .date)
                                .font(.subheadline)
                        } else {
                            Text("No Due Date")
                                .font(.subheadline)
                        }
                        if task.isRecurring {
                            Text("Recurring")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Button(action: {
                taskModel.addTask(title: "New Task", dueDate: Date(), isRecurring: false)
            }) {
                Text("Add Task")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}
