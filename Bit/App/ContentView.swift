//  ContentView.swift
//  Cosmos
//
//  Created by James Williams on 3/21/25.
//

import SwiftUI

struct AppContentView: View {  // Renamed from ContentView to avoid conflict
    var body: some View {
        MainView()
    }
}

struct AppContentView_Previews: PreviewProvider {  // Also renamed Preview struct
    static var previews: some View {
        AppContentView()
            .environmentObject(CurrencyModel())
            .environmentObject(StudyTimerModel())
            .environmentObject(ShopModel())
            .environmentObject(CivilizationModel())
            .environmentObject(MiningModel())
            .environmentObject(CategoriesViewModel())
            .environmentObject(XPModel())
    }
}
