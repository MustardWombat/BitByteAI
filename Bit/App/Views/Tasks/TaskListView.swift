import SwiftUI

struct TaskListView: View {
    @Binding var currentView: String  // added binding for currentView
    @EnvironmentObject var taskModel: TaskModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var currencyModel: CurrencyModel
    
    @State private var showTaskCreationOverlay: Bool = false
    @State private var showSortMenu: Bool = false
    
    var body: some View {
        #if os(iOS)
        let _ = print("🔍 DEBUG: TaskListView is being rendered on iOS")
        #endif
        
        ZStack {
            #if os(macOS)
            // Single column layout for macOS
            NavigationView {
                // Add this placeholder sidebar view to prevent the empty split view
                Color.clear.frame(width: 1)
                
                GeometryReader { geometry in
                    VStack(alignment: .leading, spacing: 16) {
                        // --- Top Row: Sort Dropdown and Add Button ---
                        HStack(spacing: 20) {
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
                            
                            // Add New Task Button - Positioned right after the filter button
                            Button {
                                withAnimation(.spring()) {
                                    showTaskCreationOverlay = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.green)
                                    Text("Add Task")
                                        .fontWeight(.medium)
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
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
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
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 10)
                        }
                        .background(Color.black)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Dynamic sizing
                }
                .padding(.horizontal, 5)
                .background(Color.black) // Changed from .white to .black to match app theme
                .toolbar {
                    ToolbarItem(placement: {
                        #if os(iOS)
                        return .navigationBarLeading
                        #else
                        return .automatic // Use automatic placement on macOS
                        #endif
                    }()) {
                        // Empty toolbar item - can be used later if needed
                    }
                }
            }
            .navigationViewStyle(DefaultNavigationViewStyle())
            #else
            // Standard navigation for iOS
            NavigationView {
                VStack(spacing: 16) {
                    let _ = print("🔍 DEBUG: Rendering iOS task content")
                    
                    // --- Top Row: Sort Dropdown and Add Button ---
                    HStack(spacing: 20) {
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
                            .background(Color.clear) // frame is transparent
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 1))
                        }
                        .padding(.top, 10) // Reduced from 20
                        
                        // Add New Task Button
                        Button {
                            withAnimation(.spring()) {
                                showTaskCreationOverlay = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.green)
                                Text("Add Task")
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.clear) // frame is transparent
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 1))
                        }
                        .padding(.top, 10) // Reduced from 20
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .background(Color.clear) // removed gray background behind buttons
                    
                    // --- Task List ---
                    List {
                        ForEach(taskModel.tasks.filter { task in
                            if task.isCompleted, let done = task.completedAt {
                                let _ = print("🔍 DEBUG: Task \(task.title) is completed")
                                return Date().timeIntervalSince(done) < 86400
                            }
                            let _ = print("🔍 DEBUG: Task \(task.title) is shown")
                            return true
                        }) { task in
                            HStack {
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
                                        Text("⭐️\(task.difficulty)")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                        if let due = task.dueDate {
                                            Text(dueDateDisplay(due))
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        if !task.isCompleted {
                                            Text("+\(task.xpReward) XP, +\(task.coinReward) Coins")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                Spacer()
                                if task.isCompleted {
                                    Button(action: { taskModel.removeTask(task) }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(TransparentButtonStyle())
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2)) // Add background for visibility
                            .listRowBackground(Color.black) // Ensure the row background is visible
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear) // Set transparent background
                    .onAppear {
                        print("🔍 DEBUG: List appeared with \(taskModel.tasks.count) tasks")
                    }
                }
                .padding(.horizontal, 10)
                .background(Color.clear) // Set transparent background
                .toolbar {
                    ToolbarItem(placement: {
                        #if os(iOS)
                        return .navigationBarLeading
                        #else
                        return .automatic // Use automatic placement on macOS
                        #endif
                    }()) {
                        // Empty toolbar item - can be used later if needed
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                print("🔍 DEBUG: Navigation view appeared")
                if taskModel.tasks.isEmpty {
                    print("⚠️ WARNING: No tasks in taskModel")
                }
            }
            #endif
            
            // Task creation overlay
            if showTaskCreationOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showTaskCreationOverlay = false
                        }
                    }
                
                TaskCreationOverlay(isPresented: $showTaskCreationOverlay)
                    .environmentObject(taskModel)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                    .zIndex(1)
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
}

