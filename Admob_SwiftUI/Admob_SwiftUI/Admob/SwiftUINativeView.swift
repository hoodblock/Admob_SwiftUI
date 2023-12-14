//
//  SwiftUINativeView.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/10.
//

import GoogleMobileAds
import SwiftUI
import UIKit

let NATIVESIZE: CGSize = CGSize(width: UIScreen.main.bounds.width - 20 * 2, height: 200)

public struct SwiftUINativeView: View {
    
    var objectSize: CGSize = .zero
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()

    init(objectSize: CGSize, admobModel: FirebaseAdsItemModel) {
        self.objectSize = objectSize
        self.admobModel = admobModel
    }
    
    public var body: some View {
        VStack (alignment: .center, spacing: 0) {
            NativeViewRepresentable(objectSize, admobModel)
                .frame(width: objectSize.width, height: objectSize.height, alignment: .center)
        }
    }
}

struct NativeViewRepresentable: UIViewControllerRepresentable {
        
    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var objectSize: CGSize = .zero

    init(_ objectSize: CGSize, _ admobModel: FirebaseAdsItemModel) {
        self.admobModel = admobModel
        self.objectSize = objectSize
    }
    
    func makeUIViewController(context: Context) -> NativeViewController {
        return NativeViewController(objectSize, admobModel)
    }

    func updateUIViewController(_ uiViewController: NativeViewController, context: Context) {
        
    }
}

class NativeViewController: UIViewController, GADNativeAdLoaderDelegate, GADNativeAdDelegate {

    var admobModel: FirebaseAdsItemModel = FirebaseAdsItemModel()
    var objectSize: CGSize = .zero
    private var isRequesting: Bool = false
    private let requestStatusTime: Int = 30;
    private var nativeLoader: GADAdLoader = GADAdLoader()
    private var nativeView: GADNativeAdView = GADNativeAdView()
    
    init(_ objectSize: CGSize, _ admobModel: FirebaseAdsItemModel) {
        super.init(nibName: nil, bundle: nil)
        self.admobModel = admobModel
        self.objectSize = objectSize
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        if !((CalendarTool.currentTimeInterval() - admobModel.adRealTime > admobModel.cacheSeconds) || (admobModel.nativeAd == nil)) {
            showNativeView()
        }
    }

    func loadNativeAd() {
        if !((CalendarTool.currentTimeInterval() - admobModel.adRealTime > admobModel.cacheSeconds) || (admobModel.nativeAd == nil)) {
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
        print("_______【 Firebase 】_______【 Native 】_______【 Request 】_______【 \(admobModel.ad_name) 】")
        admobModel.requestTime = CalendarTool.currentTimeInterval()
        nativeLoader = GADAdLoader(adUnitID: admobModel.ad_id, rootViewController: nil, adTypes: [.native], options: nil)
        nativeLoader.delegate = self
        nativeLoader.load(GADRequest())
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        admobModel.nativeAd = nativeAd
        admobModel.adRealTime = CalendarTool.currentTimeInterval()
        nativeAd.paidEventHandler = { value in
            
        }
        isRequesting = false;
        print("_______【 Firebase 】_______【 Native 】_______【 Request 】_______【 \(admobModel.ad_name) 】_______ 【 Success 】")
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        isRequesting = false;
        print("_______【 Firebase 】_______【 Native 】_______【 Request 】_______【 \(admobModel.ad_name) 】_______ 【 Failure __ \(error)】")
    }

    // 展示
    func showNativeView() {
        if let currentNativeAd = admobModel.nativeAd {
            nativeView = Bundle.main.loadNibNamed("SwiftUINativeAdView", owner: nil, options: nil)?.first as! GADNativeAdView
            (nativeView.headlineView as? UILabel)?.text = currentNativeAd.headline
            nativeView.mediaView?.mediaContent = currentNativeAd.mediaContent
            (nativeView.bodyView as? UILabel)?.text = currentNativeAd.body
            (nativeView.iconView as? UIImageView)?.image = currentNativeAd.icon?.image
            (nativeView.storeView as? UILabel)?.text = currentNativeAd.store
            (nativeView.priceView as? UILabel)?.text = currentNativeAd.price
            (nativeView.advertiserView as? UILabel)?.text = currentNativeAd.advertiser
            (nativeView.callToActionView as? UIButton)?.setTitle(currentNativeAd.callToAction, for: .normal)
            nativeView.nativeAd = currentNativeAd
            view.addSubview(nativeView)
            print("_______【 Firebase 】_______【 Native 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 Native Show Success 】")
            admobModel.bannerAd = nil
            admobModel.requestTime = 0
            admobModel.adRealTime = 0
            isRequesting = false;
            _ = FirebaseNetwork.shared.loadNativeAdViewModel()
        } else {
//            print("_______【 Firebase 】_______【 Native 】_______【 Show 】_______【 \(admobModel.ad_name) 】_______【 Native Show Failture 】")
        }
    }
    
        
}
