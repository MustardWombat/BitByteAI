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
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color.clear)
                    .background(.ultraThinMaterial)
                    .blur(radius: 18)
                    .opacity(0.85)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    VStack(spacing: 20) {
                        Text("Create Task")
                            .font(.headline)
                            .foregroundColor(.white)
                        TextField("Task Title", text: $title)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        VStack(alignment: .leading) {
                            Text("Difficulty")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            HStack {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: { difficulty = level }) {
                                        Image(systemName: level <= difficulty ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 24))
                                    }
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                        }
                        VStack(alignment: .leading) {
                            Text("Due Date")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Button(action: {
                                showDueDatePicker = true
                            }) {
                                HStack {
                                    if let due = dueDate {
                                        Text(due, style: .date)
                                            .foregroundColor(.white)
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
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                            }
                        }
                        HStack {
                            Button("Save") {
                                let trimmed = title.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                taskModel.addTask(title: trimmed, difficulty: difficulty, dueDate: dueDate)
                                onSave()
                                isPresented = false
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                            Button("Cancel") {
                                onCancel()
                                isPresented = false
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .padding(.horizontal, 24)
                    .frame(maxHeight: geometry.size.height * 0.55)
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: isPresented)
                }
            }
            .sheet(isPresented: $showDueDatePicker) {
                DueDatePickerView(selectedDate: $dueDate, isPresented: $showDueDatePicker)
            }
        }
    }
}
