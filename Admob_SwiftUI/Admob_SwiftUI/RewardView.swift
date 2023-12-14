//
//  RewardView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI

struct RewardView: View {
    
    @State private var isShowAd: Bool = true

    var body: some View {
        Text("Reward View")
            .presentRewardedAd(isPresented: $isShowAd, adModel: FirebaseNetwork.shared.loadRewardAdViewModel().0, showedBlock: {
                isShowAd = false
            })
    }
}

#Preview {
    RewardView()
}
