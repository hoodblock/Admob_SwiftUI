//
//  InterView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI

struct InterView: View {
    
    @State private var isShowAd: Bool = true

    var body: some View {
        Text("Inter")
            .presentInterstitialAd(isPresented: $isShowAd, adModel: FirebaseNetwork.shared.loadInterstitialAdViewModel().0, showedBlock: {
                isShowAd = false
            })
    }
}

#Preview {
    InterView()
}
