import SwiftUI

struct PlanetView: View {
    @Binding var currentView: String
    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var timerModel: StudyTimerModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var taskModel: TaskModel
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        TaskListView()
            .environmentObject(taskModel)
            .environmentObject(xpModel)
            .environmentObject(currencyModel)
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                // ...existing code...
            }
            .onChange(of: scenePhase) { newPhase in
                // ...existing code...
            }
    }
}

struct PlanetView_Previews: PreviewProvider {
    static var previews: some View {
        PlanetView(currentView: .constant("PlanetView"))
            .environmentObject(CurrencyModel())
            .environmentObject(StudyTimerModel())
            .environmentObject(XPModel())
            .environmentObject(TaskModel())
    }
}
