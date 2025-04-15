import SwiftUI

struct PlanetView: View {
    @Binding var currentView: String
    @EnvironmentObject var miningModel: MiningModel
    @EnvironmentObject var currencyModel: CurrencyModel
    @EnvironmentObject var timerModel: StudyTimerModel
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showMineConfirmation: Bool = false
    @State private var planetToMine: Planet? = nil
    
    var body: some View {
        ZStack {
            
            // Starry background overlay
            StarOverlay()
            
            VStack {
                // Add padding to the top of the assets
                VStack(spacing: 10) {
                    
                    // If a planet is currently being mined, show it separately.
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
                                // Display a large progress bar.
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
                    
                    // List of available planets that are not currently being mined.
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
                    .padding(.top, 100) // Added top padding for the assets
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(EdgeInsets(top: 5, leading: 20, bottom: 20, trailing: 20))
            }
            .ignoresSafeArea()
            .background(Color.black)
            .onAppear {
                miningModel.restoreSavedMiningState()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    miningModel.refreshMiningProgress()
                }
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
        }
    }
}
