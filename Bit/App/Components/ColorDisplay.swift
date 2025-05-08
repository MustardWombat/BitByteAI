//
//  ColorDisplay.swift
//  Cosmos
//
//  Created by James Williams on 3/24/25.
//

import SwiftUI

struct CoinDisplay_Previews: PreviewProvider {
    static var previews: some View {
        CoinDisplay().environmentObject(CurrencyModel())
    }
}
