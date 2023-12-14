//
//  BannerView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI

struct BannerView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            Text("Banner View")
            Spacer(minLength: 0)
            SwiftUIBannerView(objectSize: BANNERSIZE, admobModel: FirebaseNetwork.shared.loadBannerAdViewModel().0)
                .background(.blue)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    BannerView()
}
