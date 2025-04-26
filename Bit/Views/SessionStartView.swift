import SwiftUI

struct SessionStartView: View {
    @EnvironmentObject var timerModel: StudyTimerModel
    @State private var energyLevel = 3
    @State private var showingPicker = false
    @State private var sessionDuration: TimeInterval = 25 * 60 // 25 minutes default
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Study Session")
                .font(.title)
                .bold()
            
            VStack(alignment: .leading) {
                Text("How's your energy right now?")
                    .font(.headline)
                
                HStack {
                    ForEach(1..<6) { level in
                        Button {
                            energyLevel = level
                        } label: {
                            Image(systemName: level <= energyLevel ? "battery.100" : "battery.0")
                                .foregroundColor(level <= energyLevel ? .green : .gray)
                                .font(.system(size: 24))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if level < 5 {
                            Spacer()
                        }
                    }
                }
                .padding(.vertical)
            }
            
            Button {
                timerModel.userEnergyLevel = energyLevel
                timerModel.startTimer(for: Int(sessionDuration))
            } label: {
                Text("Start Session")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
    }
}
