//
//  ContentView.swift
//  AdmobSwitUIDemo
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import AdmobSwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    // 使用預設的 Google 測試廣告 ID
    @StateObject private var nativeViewModel = NativeAdViewModel(requestInterval: 60)
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    @StateObject private var adCoordinator = InterstitialAdCoordinator()
    @StateObject private var rewardCoordinator = RewardedAdCoordinator()
    @StateObject private var appOpenAdCoordinator = AppOpenAdCoordinator()

    @State private var hiddenNative = false
    @State private var lastReward: AdReward?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Button("Show InterstitialAd") {
                        Task {
                            do {
                                try await adCoordinator.loadAndPresent(from: adViewControllerRepresentable.viewController)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }

                    Button("show reward") {
                        Task {
                            do {
                                let reward = try await rewardCoordinator.loadAndPresent(from: adViewControllerRepresentable.viewController)
                                lastReward = reward
                                print("Reward amount: \(reward.amount) \(reward.type)")
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }

                    if let lastReward {
                        Text("Last reward: \(lastReward.amount) \(lastReward.type)")
                            .font(.footnote)
                    }

                    Button("Show App Open") {
                        Task {
                            do {
                                try await appOpenAdCoordinator.loadAndPresent(from: adViewControllerRepresentable.viewController)
                            } catch {
                                print(error.localizedDescription)
                            }
                        }
                    }

                    // 容忍失敗的場景化 API：沒廣告時只記 log 並補載
                    Button("Present App Open If Available") {
                        appOpenAdCoordinator.presentIfAvailable()
                    }

                    Button("reload native") {
                        Task {
                            try? await nativeViewModel.load()
                        }
                    }

                    Button("show ad config") {
                        AdmobSwiftUI.AdUnitIDs.printCurrentConfiguration()
                    }

                    Button("hidden native") {
                        hiddenNative.toggle()
                    }

                    NavigationLink("Banner Styles (anchored / inline / collapsible)") {
                        BannerStylesView()
                    }

                    NavigationLink("Native Ad Styles (4 templates + custom)") {
                        NativeAdStylesView()
                    }

                    NavigationLink("Legacy v2 API (deprecated)") {
                        LegacyAPIView()
                    }

                    // v3: BannerView 會依 ad size 自動保留高度，不再需要外部 frame
                    BannerView()
                        .background(Color.red)

                    // v3: 模板會依內容自動決定高度，不再需要外部 frame
                    if !hiddenNative {
                        NativeAdView(nativeViewModel: nativeViewModel, style: .banner)
                            .background(Color(UIColor.secondarySystemBackground))
                    }
                }
                .padding()
            }
            .navigationTitle("AdmobSwiftUI v3")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background {
            // Add the adViewControllerRepresentable to the background so it
            // doesn't influence the placement of other views in the view hierarchy.
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
        .onAppear {
            // App open 廣告：前景自動補載，配合 presentIfAvailable 使用
            appOpenAdCoordinator.autoReloadsOnForeground = true
            Task {
                try? await nativeViewModel.load()
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                print("App open ad ready: \(appOpenAdCoordinator.isReady)")
            }
        }
    }
}

/// 用 v2（deprecated）API 的頁面：驗證 3.x shims 只有 deprecation warning、行為照舊。
struct LegacyAPIView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel(requestInterval: 60)
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    @StateObject private var adCoordinator = InterstitialAdCoordinator()
    @StateObject private var rewardCoordinator = RewardedAdCoordinator()
    @StateObject private var appOpenAdCoordinator = AppOpenAdCoordinator()

    var body: some View {
        VStack(spacing: 20) {
            Button("Load Interstitial (v2 loadAd)") {
                adCoordinator.loadAd()
            }

            Button("Show Interstitial (v2 showAd)") {
                do {
                    try adCoordinator.showAd(from: adViewControllerRepresentable.viewController)
                } catch {
                    print(error.localizedDescription)
                }
            }

            Button("Show Reward (v2 load + showAd)") {
                Task {
                    do {
                        _ = try await rewardCoordinator.loadRewardedAd()
                        rewardCoordinator.showAd(from: adViewControllerRepresentable.viewController) { amount in
                            print("Reward amount: \(amount)")
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }

            Button("Show App Open (v2 loadAppOpenAd)") {
                Task {
                    do {
                        let ad = try await appOpenAdCoordinator.loadAppOpenAd()
                        ad.present(from: adViewControllerRepresentable.viewController)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }

            Button("Reload Native (v2 refreshAd)") {
                nativeViewModel.refreshAd()
            }

            NativeAdView(nativeViewModel: nativeViewModel, style: .banner)
                .frame(height: 80)
                .background(Color(UIColor.secondarySystemBackground))
        }
        .padding()
        .navigationTitle("Legacy v2 API")
        .navigationBarTitleDisplayMode(.inline)
        .background {
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
        .onAppear {
            nativeViewModel.refreshAd()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
