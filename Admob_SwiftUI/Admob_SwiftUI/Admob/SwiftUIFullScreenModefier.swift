//
//  SwiftUIFullScreenModefier.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/10.
//

import SwiftUI

enum AdType {
    case interstitial   // 插页
    case rewarded // 奖励
    case screen// 开屏
}

struct FullScreenModifier<Parent: View>: View {
    
    @Binding var isPresented: Bool
    @State var adType: AdType
    
    var showedBlock: () -> Void  // 展示的回调
    var adModel: FirebaseAdsItemModel
    var parent: Parent
    
    var body: some View {
        ZStack {
            parent
            if isPresented {
                EmptyView()
                    .edgesIgnoringSafeArea(.all)
                if adType == .rewarded {
                    SwiftUIRewardView(objectSize: .zero, admobModel: adModel)
                } else if adType == .interstitial {
                    SwiftUIInterstitialView(objectSize: .zero, admobModel: adModel, showedBlock: showedBlock)
                } else if adType == .screen {
                    SwiftUIStartView(objectSize: .zero, admobModel: adModel, showedBlock: showedBlock)
                }
            }
        }
    }
}

extension View {
  
    func presentRewardedAd(isPresented: Binding<Bool>, adModel: FirebaseAdsItemModel, showedBlock: @escaping (() -> Void)) -> some View {
        FullScreenModifier(isPresented: isPresented, adType: .rewarded, showedBlock: showedBlock, adModel: adModel, parent: self)
    }
    
    func presentInterstitialAd(isPresented: Binding<Bool>, adModel: FirebaseAdsItemModel, showedBlock: @escaping (() -> Void)) -> some View {
        FullScreenModifier(isPresented: isPresented, adType: .interstitial, showedBlock:  showedBlock, adModel: adModel, parent: self)
    }
    
    func presentAppOpenAd(isPresented: Binding<Bool>, adModel: FirebaseAdsItemModel, showedBlock: @escaping (() -> Void)) -> some View {
        FullScreenModifier(isPresented: isPresented, adType: .screen, showedBlock:  showedBlock, adModel: adModel, parent: self)

    }
}
