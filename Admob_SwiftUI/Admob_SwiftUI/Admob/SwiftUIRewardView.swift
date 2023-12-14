//
//  SwiftUIRewardView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/10.
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct SwiftUIRewardView: View {

    var objectSize: CGSize = .zero
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var showedBlock: () -> Void  // 展示的回调

    init(objectSize: CGSize, admobModel: FirebaseAdsItemModel, showedBlock: @escaping (() -> Void)) {
        self.objectSize = objectSize
        self.admobModel = admobModel
        self.showedBlock = showedBlock
    }
    
    public var body: some View {
        VStack (alignment: .center, spacing: 0) {
            RewardViewRepresentable(objectSize, admobModel, showedBlock: showedBlock)
                .frame(width: objectSize.width, height: objectSize.height, alignment: .center)
        }
    }
}


struct RewardViewRepresentable: UIViewControllerRepresentable {
    
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var objectSize: CGSize = .zero
    var showedBlock: () -> Void  // 展示的回调

    init(_ objectSize: CGSize, _ admobModel: FirebaseAdsItemModel, showedBlock: @escaping (() -> Void)) {
        self.admobModel = admobModel
        self.objectSize = objectSize
        self.showedBlock = showedBlock
    }
    
    func makeUIViewController(context: Context) -> RewardViewController {
        return RewardViewController(objectSize, admobModel)
    }

    func updateUIViewController(_ uiViewController: RewardViewController, context: Context) {
        
    }
}

class RewardViewController: UIViewController, GADFullScreenContentDelegate {
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var objectSize: CGSize = .zero
    var showedBlock: () -> Void  // 展示的回调

    private var isRequesting: Bool = false
    private let requestStatusTime: Int = 30;
    private var rewardedAd: GADRewardedAd = GADRewardedAd()

    init(_ objectSize: CGSize, _ admobModel: FirebaseAdsItemModel, _ showedBlock: @escaping (() -> Void) = {}) {
        self.showedBlock = showedBlock
        super.init(nibName: nil, bundle: nil)
        self.admobModel = admobModel
        self.objectSize = objectSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !((CalendarTool.currentTimeInterval() - admobModel.adRealTime > admobModel.cacheSeconds) || (admobModel.rewardedAd == nil)) {
            Dispatch.DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                self.showRewardView()
            }
        }
    }

    func loadRewardAd() {
        if !((CalendarTool.currentTimeInterval() - admobModel.adRealTime > admobModel.cacheSeconds) || (admobModel.rewardedAd == nil)) {
            return
        }
        if isRequesting {
            if (CalendarTool.currentTimeInterval() - admobModel.requestTime > requestStatusTime) {
                self.isRequesting = false;
            } else {
                return;
            }
        }
        isRequesting = true
        print("_______【 Firebase 】_______【 Reward 】_______【 Request 】_______【 \(admobModel.ad_name) 】")
        admobModel.requestTime = CalendarTool.currentTimeInterval()
        GADRewardedAd.load(withAdUnitID: admobModel.ad_id, request: GADRequest()) { [self] rewardedAd, err in
            if let err = err {
                print("_______【 Firebase 】_______【 Reward 】_______【 Request 】_______【 \(admobModel.ad_name) 】_______ 【 Failure __ \(err)】")
                return
            } else {
                admobModel.adRealTime = CalendarTool.currentTimeInterval()
                admobModel.rewardedAd = rewardedAd
                rewardedAd!.paidEventHandler = { value in
                    
                }
                print("_______【 Firebase 】_______【 Reward 】_______【 Request 】_______【 \(admobModel.ad_name) 】_______ 【 Success 】")
            }
            isRequesting = false
        }
    }

    // 点击广告取消按钮，让广告消失
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        admobModel.rewardedAd = nil
        admobModel.requestTime = 0
        admobModel.adRealTime = 0
        isRequesting = false
        print("_______【 Firebase 】_______【 Reward 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 adDidDismissFullScreenContent 】")
        _ = FirebaseNetwork.shared.loadRewardAdViewModel()
        showedBlock()
    }

    // 广告展示失败
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        admobModel.rewardedAd = nil
        admobModel.requestTime = 0
        admobModel.adRealTime = 0
        isRequesting = false
//        print("_______【 Firebase 】_______【 Reward 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 \(error) 】_______【 didFailToPresentFullScreenContentWithError 】")
//        _ = FirebaseNetwork.shared.loadRewardAdViewModel()
    }
    
    func showRewardView() {
        if let currentRewardAd = admobModel.rewardedAd {
            rewardedAd = currentRewardAd
            rewardedAd.fullScreenContentDelegate = self
            rewardedAd.present(fromRootViewController: self) {
                // block
            }
            print("_______【 Firebase 】_______【 Reward 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 Reward Show Success 】")
        } else {
//            print("_______【 Firebase 】_______【 Interstitial 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 Interstitial Show Failture 】")
        }
    }
    
}
