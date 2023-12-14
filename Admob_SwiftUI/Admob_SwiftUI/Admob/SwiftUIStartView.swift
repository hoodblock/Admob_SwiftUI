//
//  SwiftUIStartView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/10.
//

import GoogleMobileAds
import SwiftUI
import UIKit

struct SwiftUIStartView: View {

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
            StartViewRepresentable(objectSize, admobModel, showedBlock: showedBlock)
                .frame(width: objectSize.width, height: objectSize.height, alignment: .center)
        }
    }
}


struct StartViewRepresentable: UIViewControllerRepresentable {
    
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var objectSize: CGSize = .zero
    var showedBlock: () -> Void  // 展示的回调

    init(_ objectSize: CGSize, _ admobModel: FirebaseAdsItemModel, showedBlock: @escaping (() -> Void)) {
        self.admobModel = admobModel
        self.objectSize = objectSize
        self.showedBlock = showedBlock
    }
    
    func makeUIViewController(context: Context) -> StartViewController {
        return StartViewController(objectSize, admobModel, showedBlock)
    }

    func updateUIViewController(_ uiViewController: StartViewController, context: Context) {
        
    }
}

class StartViewController: UIViewController, GADFullScreenContentDelegate {
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var objectSize: CGSize = .zero
    var showedBlock: () -> Void  // 展示的回调
    private var isRequesting: Bool = false
    private let requestStatusTime: Int = 30;
    private var startAd: GADAppOpenAd = GADAppOpenAd()

    init(_ objectSize: CGSize, _ admobModel: FirebaseAdsItemModel, _ showedBlock: @escaping (() -> Void) = {}) {
        self.showedBlock = showedBlock
        super.init(nibName: nil, bundle: nil)
        self.admobModel = admobModel
        self.objectSize = objectSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !((CalendarTool.currentTimeInterval() - admobModel.adRealTime > admobModel.cacheSeconds) || (admobModel.startAd == nil)) {
            Dispatch.DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                self.showStartView()
            }
        }
    }
    
    func loadStartAd() {
        if !((CalendarTool.currentTimeInterval() - admobModel.adRealTime > admobModel.cacheSeconds) || (admobModel.startAd == nil)) {
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
        print("_______【 Firebase 】_______【 Start 】_______【 Request 】_______【 \(admobModel.ad_name) 】")
        admobModel.requestTime = CalendarTool.currentTimeInterval()
        GADAppOpenAd.load(withAdUnitID: admobModel.ad_id, request: GADRequest()) { [self] appOpen, err in
            if let err = err {
                print("_______【 Firebase 】_______【 Start 】_______【 Request 】_______【 \(admobModel.ad_name) 】_______ 【 Failure __ \(err)】")
                return
            } else {
                admobModel.adRealTime = CalendarTool.currentTimeInterval()
                admobModel.startAd = appOpen;
                appOpen!.paidEventHandler = { value in
                    
                }
                print("_______【 Firebase 】_______【 Start 】_______【 Request 】_______【 \(admobModel.ad_name) 】_______ 【 Success 】")
            }
            isRequesting = false
            
            NotificationCenter.default.post(name: Notification.Name(NOTIFICATION_AD_REQUEST_SUCCESS), object: nil)
        }
    }
  
    // 点击广告取消按钮，让广告消失
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        admobModel.startAd = nil
        admobModel.requestTime = 0
        admobModel.adRealTime = 0
        isRequesting = false
        print("_______【 Firebase 】_______【 Start 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 adDidDismissFullScreenContent 】")
        _ = FirebaseNetwork.shared.loadStartAdViewModel()
        showedBlock()
    }

    // 广告展示失败
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        admobModel.startAd = nil
        admobModel.requestTime = 0
        admobModel.adRealTime = 0
        isRequesting = false
//        print("_______【 Firebase 】_______【 Start 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 didFailToPresentFullScreenContentWithError 】")
//        _ = FirebaseNetwork.shared.loadStartAdViewModel()
    }
    
    func showStartView() {
        if let currentStartAd = admobModel.startAd {
            startAd = currentStartAd
            startAd.fullScreenContentDelegate = self
            startAd.present(fromRootViewController: self)
            print("_______【 Firebase 】_______【 Start 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 Start Show Success 】")
        } else {
//            print("_______【 Firebase 】_______【 Start 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 Start Show Failture 】")
        }
    }
    
}
