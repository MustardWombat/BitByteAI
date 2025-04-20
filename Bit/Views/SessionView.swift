//
//  SessionView.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import SwiftUI

struct SessionView: View {
    @Binding var currentView: String
    
    var body: some View {
        ZStack {
            StarOverlay() // Add the starry background
            VStack {
                StudyTimerView()
                Spacer()
            }
        }
    }
}
