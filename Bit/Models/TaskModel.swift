import Foundation
import Combine
import SwiftUI // Add this import

enum TaskSortOption: String, CaseIterable, Identifiable {
    case dueDate = "Due Date"
    case difficulty = "Difficulty"
    case completed = "Completed"
    case created = "Created"

    var id: String { self.rawValue }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var xpReward: Int
    var coinReward: Int
    var difficulty: Int // 1 (easy) to 5 (hard)
    var dueDate: Date?
    var createdAt: Date

    init(title: String, xpReward: Int = 20, coinReward: Int = 10, difficulty: Int = 3, dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.xpReward = xpReward
        self.coinReward = coinReward
        self.difficulty = difficulty
        self.dueDate = dueDate
        self.createdAt = Date()
    }
}

class TaskModel: ObservableObject {
    @Published var tasks: [TaskItem] = [] {
        didSet { 
            saveLocalTasks()  // always save locally
            if isSignedIn { saveCloudTasks() }
        }
    }

    @Published var sortOption: TaskSortOption = .dueDate {
        didSet { sortTasks(by: sortOption) }
    }

    @AppStorage("isSignedIn") private var isSignedIn: Bool = false

    private let tasksKey = "UserTasks"
    private let localTasksKey = "Local_UserTasks"

    init() {
        loadTasks()
        sortTasks(by: sortOption)
    }

    func addTask(title: String, xpReward: Int = 20, coinReward: Int = 10, difficulty: Int = 3, dueDate: Date? = nil) {
        let task = TaskItem(title: title, xpReward: xpReward, coinReward: coinReward, difficulty: difficulty, dueDate: dueDate)
        tasks.append(task)
        sortTasks(by: sortOption)
    }

    func completeTask(_ task: TaskItem, xpModel: XPModel, currencyModel: CurrencyModel) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id && !$0.isCompleted }) {
            tasks[idx].isCompleted = true
            xpModel.addXP(tasks[idx].xpReward)
            currencyModel.earn(amount: tasks[idx].coinReward)
            sortTasks(by: sortOption)
        }
    }

    func removeTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }

    func sortTasks(by option: TaskSortOption) {
        switch option {
        case .dueDate:
            tasks.sort {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }
                switch ($0.dueDate, $1.dueDate) {
                case let (d1?, d2?):
                    return d1 < d2
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return $0.createdAt < $1.createdAt
                }
            }
        case .difficulty:
            tasks.sort {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }
                return $0.difficulty > $1.difficulty
            }
        case .completed:
            tasks.sort { !$0.isCompleted && $1.isCompleted }
        case .created:
            tasks.sort { $0.createdAt < $1.createdAt }
        }
    }

    private func saveLocalTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: localTasksKey)
        }
    }

    internal func loadTasks() {
        if let cloudData = NSUbiquitousKeyValueStore.default.data(forKey: tasksKey),
           let cloudTasks = try? JSONDecoder().decode([TaskItem].self, from: cloudData) {
            tasks = cloudTasks
        } else if let localData = UserDefaults.standard.data(forKey: localTasksKey),
                  let localTasks = try? JSONDecoder().decode([TaskItem].self, from: localData) {
            tasks = localTasks
        }
    }

    private func saveCloudTasks() {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: tasksKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
