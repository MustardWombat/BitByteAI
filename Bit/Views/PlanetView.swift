import SwiftUI

struct PlanetView: View {
    @Binding var currentView: String
    @EnvironmentObject var miningModel: MiningModel
    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var timerModel: StudyTimerModel
    @EnvironmentObject var xpModel: XPModel
    @EnvironmentObject var taskModel: TaskModel
    @Environment(\.scenePhase) var scenePhase

    @State private var showMineConfirmation: Bool = false
    @State private var planetToMine: Planet? = nil
    @State private var selectedTab: Int = 0 // 0 = Mining, 1 = Tasks

    var body: some View {
        ZStack {
            StarOverlay()
            VStack {
                Picker(selection: $selectedTab, label: Text("Category")) {
                    Text("Mining").tag(0)
                    Text("Tasks").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 16)
                .padding(.horizontal, 20)

                if selectedTab == 0 {
                    VStack(spacing: 10) {
                        if let current = miningModel.currentMiningPlanet {
                            VStack(spacing: 10) {
                                Text("Currently Mining:")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(current.name)
                                            .foregroundColor(.white)
                                            .font(.headline)
                                        Text("Reward: \(current.miningReward)")
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    VStack {
                                        ProgressView(value: miningModel.miningProgress)
                                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                                            .frame(width: 200)
                                        Text("Mining... \(Int(miningModel.miningProgress * 100))%")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                            }
                        }
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(miningModel.availablePlanets) { planet in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(planet.name)
                                                .foregroundColor(.white)
                                                .font(.headline)
                                            Text("Reward: \(planet.miningReward)")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        }
                                        Spacer()
                                        Button("Mine") {
                                            planetToMine = planet
                                            showMineConfirmation = true
                                        }
                                        .disabled(miningModel.currentMiningPlanet != nil)
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.top, 100)
                        .padding(.horizontal, 20)
                        Spacer()
                    }
                    .padding(EdgeInsets(top: 5, leading: 20, bottom: 20, trailing: 20))
                } else {
                    TaskListView()
                        .environmentObject(taskModel)
                        .environmentObject(xpModel)
                        .environmentObject(currencyModel)
                }
            }
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                miningModel.restoreSavedMiningState()
            }
            .onChange(of: scenePhase) { newPhase in
                #if os(iOS) || os(macOS)
                if newPhase == .active {
                    miningModel.refreshMiningProgress()
                }
                #endif
            }
            .alert(isPresented: $showMineConfirmation) {
                Alert(
                    title: Text("Confirm Mining"),
                    message: Text("Do you want to mine \(planetToMine?.name ?? "this planet")?"),
                    primaryButton: .default(Text("Mine")) {
                        if let planet = planetToMine {
                            miningModel.startMining(planet: planet, inFocusMode: timerModel.isTimerRunning)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    struct PlanetView_Previews: PreviewProvider {
        static var previews: some View {
            PlanetView(currentView: .constant("PlanetView"))
                .environmentObject(CurrencyModel())
                .environmentObject(StudyTimerModel())
                .environmentObject(MiningModel())
                .environmentObject(XPModel())
                .environmentObject(TaskModel())
        }
    }
}
