//
//  FocusCheckView.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//
//  The "FocusCheckView" View is responsible for the logic
//  Behind determining if the user was "focused"
//  (currently has no implementation)

import SwiftUI

struct FocusCheckView: View {
    var onAnswer: (Bool) -> Void
    @EnvironmentObject var timerModel: StudyTimerModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.yellow)
                Text("Focus Check")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                Text("Did you stay focused while away?")
                    .font(.title2)
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    Button("Yes, I stayed focused") {
                        // Record this as high engagement
                        timerModel.recordFocusLevel(0.9)
                        onAnswer(true)
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    
                    Button("No, I got distracted") {
                        // Record this as lower engagement
                        timerModel.recordFocusLevel(0.4)
                        onAnswer(false)
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}
