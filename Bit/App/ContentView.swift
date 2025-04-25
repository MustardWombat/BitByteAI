//  ContentView.swift
//  Cosmos
//
//  Created by James Williams on 3/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CurrencyModel())
            .environmentObject(StudyTimerModel())
            .environmentObject(ShopModel())
            .environmentObject(CivilizationModel())
            .environmentObject(MiningModel())
            .environmentObject(CategoriesViewModel())
            .environmentObject(XPModel())


    }
}
