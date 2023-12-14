//
//  Admob_SwiftUIApp.swift
//  Admob_SwiftUI
//
//  Created by hood on 2023/12/13.
//

import SwiftUI
import FBAudienceNetwork
import FBAEMKit
import FBSDKCoreKit
import FBSDKCoreKit_Basics
import FirebaseCore
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        FirebaseNetwork.shared.loadRemoteFirebaseConfig()
        return true
    }
}

@main
struct Admob_SwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    @State private var canShowStartAdView: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .center, content: {
                if canShowStartAdView {
                    AdLaunchPage(canShowStartAdView: $canShowStartAdView)
                } else {
                    ContentView()
                }
            })
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active: appActiveStatus()
            case .inactive: appInactiveStatus()
            case .background: appBackgroundStatus()
            @unknown default:
                print("_______________【 APP Default   （在后台）】_______________")
            }
        }
    }
    
    func appActiveStatus() {
        print("_______________【 APP Active    （活跃）】_______________")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PermissionRequest.requestIDFAPermission()
        }
        canShowStartAdView = true
    }
    
    func appInactiveStatus() {
        print("_______________【 APP Inactive  （休眠）】_______________")

    }
    
    func appBackgroundStatus() {
        print("_______________【 APP Background（在后台）】_______________")
    }
}


class PermissionRequest: NSObject {
    static func requestIDFAPermission() {
        if #available(iOS 14, *) {
            #if DEBUG
            print("IDFA status = \(ATTrackingManager.trackingAuthorizationStatus)")
            #endif
            let status = ATTrackingManager.trackingAuthorizationStatus
            switch status {
            case .notDetermined:
                ATTrackingManager.requestTrackingAuthorization { status in
                }
            default:
                print("_______________【 APP ATTrackingManager （授权失败）】_______________")
            }
        }
    }
}



// MARK: - 广告启动页
struct AdLaunchPage: View {
    
    @Binding var canShowStartAdView: Bool
    @State private var progress: CGFloat = 0.0          // 当前位置
    @State private var timeAllProgress: CGFloat = 15    // 总时间 10秒
    @State private var timeProgress: CGFloat = 0.05     // 每个时间间隔
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    let progressDefaultWidth: CGFloat =  UIScreen.main.bounds.size.width - 40 * 2

    @State private var showAd: Bool = false
    @State private var isReceiveAdsNotification: Bool = false

    var body: some View {
        GeometryReader { geometryProxy in
            VStack (alignment: .center) {
                Spacer()
                Image(systemName: "figure.walk")
                    .resizable()
                    .frame(width: 130, height: 130)
                Text("APP NAME")
                Spacer()
                ZStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Rectangle()
                            .foregroundColor(.gray)
                            .frame(width: progressDefaultWidth, height: 8, alignment: .center)
                            .cornerRadius(4)
                    }
                    HStack(alignment: .center) {
                        VStack(alignment: .center) {
                            Rectangle()
                                .frame(width: progress, height: 8, alignment: .center)
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                                .onAppear {
                                    timer = Timer.publish(every: timeProgress, on: .main, in: .common).autoconnect()
                                }
                        }
                        Spacer(minLength: 0)
                    }
                }
                .padding([.leading, .trailing, .bottom], 40)
            }
        }
        .ignoresSafeArea(.all)
        .onReceive(timer) { _ in
            if progress < progressDefaultWidth {
                let increment = (progressDefaultWidth / timeAllProgress) * timeProgress
                if isReceiveAdsNotification {
                    timeProgress += 0.05
                }
                progress += increment
            } else {
                progress = progressDefaultWidth
                withAnimation {
                    showAd = true
                }
                timer.upstream.connect().cancel()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(NOTIFICATION_AD_REQUEST_SUCCESS))) { _ in
            isReceiveAdsNotification = true
        }
        .presentAppOpenAd(isPresented: $showAd, adModel: FirebaseNetwork.shared.loadStartAdViewModel().0, showedBlock: {
            canShowStartAdView = false
        })
        .onAppear {
            if FirebaseNetwork.shared.loadStartAdViewModel().1 {
                isReceiveAdsNotification = true
            }
        }
    }
}
