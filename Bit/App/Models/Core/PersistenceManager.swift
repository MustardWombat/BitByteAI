import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let key = "categories"
    private init() {}

    func saveCategory(_ category: Category) {
        var categories = loadCategories()
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func loadCategories() -> [Category] {
        if let data = UserDefaults.standard.data(forKey: key),
           let categories = try? JSONDecoder().decode([Category].self, from: data) {
            return categories
        }
        return []
    }
}
