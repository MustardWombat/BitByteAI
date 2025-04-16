import Foundation
import Combine

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var xpReward: Int
    var coinReward: Int

    init(title: String, xpReward: Int = 20, coinReward: Int = 10) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.xpReward = xpReward
        self.coinReward = coinReward
    }
}

class TaskModel: ObservableObject {
    @Published var tasks: [TaskItem] = [] {
        didSet { saveTasks() }
    }

    private let tasksKey = "UserTasks"

    init() {
        loadTasks()
    }

    func addTask(title: String, xpReward: Int = 20, coinReward: Int = 10) {
        let task = TaskItem(title: title, xpReward: xpReward, coinReward: coinReward)
        tasks.append(task)
    }

    func completeTask(_ task: TaskItem, xpModel: XPModel, currencyModel: CurrencyModel) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].isCompleted = true
            xpModel.addXP(tasks[idx].xpReward)
            currencyModel.earn(amount: tasks[idx].coinReward)
        }
    }

    func removeTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }

    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let saved = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = saved
        }
    }
}
