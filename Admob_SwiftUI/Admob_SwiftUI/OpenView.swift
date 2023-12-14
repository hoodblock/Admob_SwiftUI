//
//  OpenView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI

struct OpenView: View {
    
    @State private var isShowAd: Bool = true
    
    var body: some View {
        Text("Open View")
            .presentAppOpenAd(isPresented: $isShowAd, adModel: FirebaseNetwork.shared.loadStartAdViewModel().0) {
                isShowAd = false
            }
    }
}

#Preview {
    OpenView()
}
