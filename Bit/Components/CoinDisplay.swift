//
//  CoinDisplay.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//
//  The "CoinDisplay" component is responsible for the logic
//  Behind displaying coins which can be used throughout the program

import SwiftUI

struct CoinDisplay: View {
    @EnvironmentObject var currencyModel: CurrencyModel

    var body: some View {
        HStack(spacing: 4) {
            Image("coin") // Ensure "coin" exists in Assets
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text("\(currencyModel.balance)")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
