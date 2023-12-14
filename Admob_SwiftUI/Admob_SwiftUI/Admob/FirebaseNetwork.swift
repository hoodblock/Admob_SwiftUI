//
//  FirebaseNet.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/7.
//

import Foundation
import FirebaseCore
import GoogleMobileAds
import AdSupport
import SwiftUI
import HandyJSON
import FirebaseCore
import FirebaseInstallations
import FirebaseRemoteConfig
import UIKit


struct CalendarTool {
    
    let currentDate = Date()
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
  
    static func currentTimeInterval() -> Int64 {
        let now = Date()
        let dformatter = DateFormatter()
        dformatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeInterval: TimeInterval = now.timeIntervalSince1970
        return CLongLong(timeInterval)
    }
}



// FirebaseModel 配置数据
class FirebaseConfigModel: HandyJSON {
    var ad_controller: FirebaseEventModel           = FirebaseEventModel()
    var ad_detail: FirebaseAdsModel           =  FirebaseAdsModel()
    required init() {
        self.ad_controller                          = FirebaseEventModel()
        self.ad_detail                              = FirebaseAdsModel()
    }
}

class FirebaseAdsItemModel: HandyJSON {
    required init() {
    }
    var ad_id: String                               = String()
    var ad_type: String                             = String()
    var ad_name: String                             = String()
    var ad_repeatRequest: Int                       = 1                                     // 重复请求，就是两个一样的广告
    // 额外数据（基础）
    var requestTime: Int64                          = CalendarTool.currentTimeInterval()
    var adRealTime: Int64                           = CalendarTool.currentTimeInterval()    // 请求到数据之后的创建时间，用来判断是否过期
    var cacheSeconds: Int64                         = 60 * 60                               // 广告缓存时间(3600秒，一小时)

    // 额外数据（进阶）
    var startAd: GADAppOpenAd?
    var nativeAd: GADNativeAd?
    var bannerAd: GADBannerView?
    var interstitialAd: GADInterstitialAd?
    var rewardedAd: GADRewardedAd?

    required init(_ itemModel: FirebaseAdsItemModel) {
        ad_id = itemModel.ad_id
        ad_type = itemModel.ad_type
        ad_name = itemModel.ad_name
        ad_repeatRequest = itemModel.ad_repeatRequest
        requestTime = itemModel.requestTime
        adRealTime = itemModel.adRealTime
        cacheSeconds = itemModel.cacheSeconds
        
        // 额外数据（进阶）
        startAd = itemModel.startAd
        nativeAd = itemModel.nativeAd
        bannerAd = itemModel.bannerAd
        interstitialAd = itemModel.interstitialAd
        rewardedAd = itemModel.rewardedAd
    }
}

struct FirebaseAdsModel: HandyJSON {
    var value_ad: [FirebaseAdsItemModel]       = []
    
    var value_ads: [[FirebaseAdsItemModel]] {
        return [value_ad]
    }
}

struct FirebaseEventModel: HandyJSON {
    var enable_native: Bool                         = false
    var enable_inter: Bool                          = false
    var enable_banner: Bool                         = false
}

enum AdsType: Int {
    case start                                      = 0 // 开屏广告
    case inter                                      = 1 // 插页广告
    case banner                                     = 2 // 横幅广告
    case native                                     = 3 // 原生广告
    case reward                                     = 4 // 激励广告
}
 

let NOTIFICATION_AD_REQUEST_SUCCESS :String = "notification_ad_request_success"

 // 瀑布流广告
class FirebaseNetwork {
    
    static let shared = FirebaseNetwork()
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var firebaseConfigModel: FirebaseConfigModel = FirebaseConfigModel()
    
    var bannerAds: [BannerViewController] = []
    var startAds: [StartViewController] = []
    var interAds: [InterstitialViewController] = []
    var nativeAds: [NativeViewController] = []
    var rewardAds: [RewardViewController] = []

    init() {
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [""]
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        let remoteSettings = RemoteConfigSettings()
        remoteSettings.minimumFetchInterval = 0
        remoteConfig.configSettings = remoteSettings
        loadLocalCacheFirebaseAdmobConfig()
    }
    
    // 本地firebase 数据
    private func loadLocalCacheFirebaseAdmobConfig() {
        // 读取配置数据
        guard let fileURL = Bundle.main.url(forResource: "FirebaseAdmobConfigJson", withExtension: "geojson") else {
            print("_______【 Firebase 】_______【 未找到 广告配置本地文件 】")
            return
        }
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let jsonString = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            firebaseConfigModel.ad_controller = FirebaseEventModel.deserialize(from: jsonString, designatedPath: "ad_controller") ?? FirebaseEventModel()
            firebaseConfigModel.ad_detail = FirebaseAdsModel.deserialize(from: jsonString, designatedPath: "ad_detail") ?? FirebaseAdsModel()
       } catch {
           print("_______【 Firebase 】_______【 解析本地啊广告配置失败 】")
       }
    }
    
    // 远端firebase 数据
    func loadRemoteFirebaseConfig() {
        remoteConfig.fetchAndActivate { [self] (status, error) in
            guard error == nil else {
                print("Error fetching remote config: \(error!.localizedDescription)")
                requestAds()
                return
            }
            // TODO: 如果有远端配置，换成远端配置
//            let message = remoteConfig.configValue(forKey: "MESSAGE").stringValue ?? "Default Message"
            DispatchQueue.main.async { [self] in
//                firebaseConfigModel.ad_controller = FirebaseEventModel.deserialize(from: jsonString, designatedPath: "ad_controller") ?? FirebaseEventModel()
//                firebaseConfigModel.ad_detail = FirebaseAdsModel.deserialize(from: jsonString, designatedPath: "ad_detail") ?? FirebaseAdsModel()
                requestAds()
            }
        }
    }
    
    // 全新请求广告数据，会清除历史广告数据
    func requestAds() {
        loadStartAds()
        // 延长执行
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loadDefaultAds()
        }
    }
    
    // 以ID为单位，每个ID里有多个（高中低）数据，按顺序去取
    private func loadStartAds() {
        loadStartViewAds()
    }
    
    private func loadDefaultAds() {
        loadNativeViewAds()
        loadInterstitialViewAds()
        loadBannerViewAds()
        loadRewardViewAds()
    }
    
}


// MARK: Start / Open 开屏广告
extension FirebaseNetwork {
    
    private func loadStartViewAds() {
        startAds = []
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            for item in itemValue {
                if item.ad_type.contains("OPEN") {
                    for _ in 0..<item.ad_repeatRequest {
                        let viewController = StartViewController(.zero, FirebaseAdsItemModel(item))
                        viewController.loadStartAd()
                        startAds.append(viewController)
                    }
                }
            }
        }
    }
    
    // 更新广告数据,不管重复多少个，必须把重复的全部使用完再请求
    func loadStartAdViewModel() -> (FirebaseAdsItemModel, Bool) {
        var findModel: FirebaseAdsItemModel?
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            // high / mid / all
            var find: Bool = false
            for indexValue in itemValue {
                for adItem in startAds {
                    if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                        if !((CalendarTool.currentTimeInterval() - adItem.admobModel.adRealTime > adItem.admobModel.cacheSeconds) || (adItem.admobModel.startAd == nil)) {
                            if !find {
                                if findModel == nil {
                                    findModel = adItem.admobModel
                                }
                                find = true
                                break
                            }
                        }
                    }
                }
                if !find {
                    for adItem in startAds {
                        if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                            adItem.loadStartAd()
                        }
                    }
                }
            }
        }
        return (findModel ?? FirebaseAdsItemModel(), (findModel?.ad_id.count ?? 0) > 0 ? true : false)
    }
}

// MARK: INTERSTITIAL / Interstitial 插页广告
extension FirebaseNetwork {
    
    private func loadInterstitialViewAds() {
        interAds = []
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            for item in itemValue {
                if item.ad_type.contains("INTERSTITIAL") {
                    for _ in 0..<item.ad_repeatRequest {
                        let viewController = InterstitialViewController(.zero, FirebaseAdsItemModel(item))
                        viewController.loadInterstitialAd()
                        interAds.append(viewController)
                    }
                }
            }
        }
    }
    
    // 更新广告数据,不管重复多少个，必须把重复的全部使用完再请求
    func loadInterstitialAdViewModel() -> (FirebaseAdsItemModel, Bool) {
        var findModel: FirebaseAdsItemModel?
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            // high / mid / all
            var find: Bool = false
            for indexValue in itemValue {
                for adItem in interAds {
                    if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                        if !((CalendarTool.currentTimeInterval() - adItem.admobModel.adRealTime > adItem.admobModel.cacheSeconds) || (adItem.admobModel.interstitialAd == nil)) {
                            if !find {
                                if findModel == nil {
                                    findModel = adItem.admobModel
                                }
                                find = true
                                break
                            }
                        }
                    }
                }
                if !find {
                    for adItem in interAds {
                        if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                            adItem.loadInterstitialAd()
                        }
                    }
                }
            }
        }
        return (findModel ?? FirebaseAdsItemModel(), (findModel?.ad_id.count ?? 0) > 0 ? true : false)
    }
}

// MARK: Banner 横幅广告
extension FirebaseNetwork {
    
    private func loadBannerViewAds() {
        bannerAds = []
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            for item in itemValue {
                if item.ad_type.contains("BANNER") {
                    for _ in 0..<item.ad_repeatRequest {
                        let viewController = BannerViewController(BANNERSIZE, FirebaseAdsItemModel(item))
                        viewController.loadBannerAd()
                        bannerAds.append(viewController)
                    }
                }
            }
        }
    }
    
    // 更新广告数据,不管重复多少个，必须把重复的全部使用完再请求
    func loadBannerAdViewModel() -> (FirebaseAdsItemModel, Bool) {
        var findModel: FirebaseAdsItemModel?
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            // high / mid / all
            var find: Bool = false
            for indexValue in itemValue {
                for adItem in bannerAds {
                    if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                        if !((CalendarTool.currentTimeInterval() - adItem.admobModel.adRealTime > adItem.admobModel.cacheSeconds) || (adItem.admobModel.bannerAd == nil)) {
                            if !find {
                                if findModel == nil {
                                    findModel = adItem.admobModel
                                }
                                find = true
                                break
                            }
                        }
                    }
                }
                if !find {
                    for adItem in bannerAds {
                        if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                            adItem.loadBannerAd()
                        }
                    }
                }
            }
        }
        return (findModel ?? FirebaseAdsItemModel(), (findModel?.ad_id.count ?? 0) > 0 ? true : false)
    }
}

// MARK: Native 原生广告
extension FirebaseNetwork {
    
    private func loadNativeViewAds() {
        nativeAds = []
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            for item in itemValue {
                if item.ad_type.contains("NATIVE") {
                    for _ in 0..<item.ad_repeatRequest {
                        let viewController = NativeViewController(BANNERSIZE, FirebaseAdsItemModel(item))
                        viewController.loadNativeAd()
                        nativeAds.append(viewController)
                    }
                }
            }
        }
    }
    
    // 更新广告数据,不管重复多少个，必须把重复的全部使用完再请求
    func loadNativeAdViewModel() -> (FirebaseAdsItemModel, Bool) {
        var findModel: FirebaseAdsItemModel?
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            // high / mid / all
            var find: Bool = false
            for indexValue in itemValue {
                for adItem in nativeAds {
                    if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                        if !((CalendarTool.currentTimeInterval() - adItem.admobModel.adRealTime > adItem.admobModel.cacheSeconds) || (adItem.admobModel.nativeAd == nil)) {
                            if !find {
                                if findModel == nil {
                                    findModel = adItem.admobModel
                                }
                                find = true
                                break
                            }
                        }
                    }
                }
                if !find {
                    for adItem in nativeAds {
                        if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                            adItem.loadNativeAd()
                        }
                    }
                }
            }
        }
        return (findModel ?? FirebaseAdsItemModel(), (findModel?.ad_id.count ?? 0) > 0 ? true : false)
    }
}

// MARK: REWARD / Reward 激励广告
extension FirebaseNetwork {
    
    private func loadRewardViewAds() {
        rewardAds = []
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            for item in itemValue {
                if item.ad_type.contains("REWARD") {
                    for _ in 0..<item.ad_repeatRequest {
                        let viewController = RewardViewController(.zero, FirebaseAdsItemModel(item))
                        viewController.loadRewardAd()
                        rewardAds.append(viewController)
                    }
                }
            }
        }
    }
    
    // 更新广告数据,不管重复多少个，必须把重复的全部使用完再请求
    func loadRewardAdViewModel() -> (FirebaseAdsItemModel, Bool) {
        var findModel: FirebaseAdsItemModel?
        for itemValue in firebaseConfigModel.ad_detail.value_ads {
            // high / mid / all
            var find: Bool = false
            for indexValue in itemValue {
                for adItem in rewardAds {
                    if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                        if !((CalendarTool.currentTimeInterval() - adItem.admobModel.adRealTime > adItem.admobModel.cacheSeconds) || (adItem.admobModel.rewardedAd == nil)) {
                            if !find {
                                if findModel == nil {
                                    findModel = adItem.admobModel
                                }
                                find = true
                                break
                            }
                        }
                    }
                }
                if !find {
                    for adItem in rewardAds {
                        if (adItem.admobModel.ad_id == indexValue.ad_id) && (adItem.admobModel.ad_name == indexValue.ad_name)  {
                            adItem.loadRewardAd()
                        }
                    }
                }
            }
        }
        return (findModel ?? FirebaseAdsItemModel(), (findModel?.ad_id.count ?? 0) > 0 ? true : false)
    }
}
