//
//  NativeView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI

struct NativeView: View {
    var body: some View {
        VStack (alignment: .center, spacing: 20) {
            Spacer(minLength: 0)
            Text("Native View")
            Spacer(minLength: 0)
            SwiftUINativeView(objectSize: NATIVESIZE, admobModel: FirebaseNetwork.shared.loadNativeAdViewModel().0)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    NativeView()
}
