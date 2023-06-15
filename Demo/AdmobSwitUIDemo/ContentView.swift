//
//  ContentView.swift
//  AdmobSwitUIDemo
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import AdmobSwiftUI

struct ContentView: View {
    @StateObject private var nativeViewModel = NativeAdViewModel()
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let adCoordinator = InterstitialAdCoordinator()
    private let rewardCoordinator = RewardedAdCoordinator()
    
    var body: some View {
        ScrollView {
            VStack (spacing: 20) {
                Button("Show InterstitialAd") {
                    Task {
                        do {
                            let ad = try await adCoordinator.loadAppOpenAd()
                            ad.present(fromRootViewController: adViewControllerRepresentable.viewController)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                Button("show reward") {
                    Task {
                        do {
                            let reward = try await rewardCoordinator.loadInterstitialAd()
                            reward.present(fromRootViewController: adViewControllerRepresentable.viewController) {
                                print("Reward amount: \(reward.adReward.amount)")
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                
                Button("reload native") {
                    nativeViewModel.refreshAd()
                }
                
                BannerView()
                    .frame(height: 50)
                    .background(Color.red)
                
                NativeAdView(nativeViewModel: nativeViewModel, style: .banner)
                    .frame(height: 80)
                    .background(Color(UIColor.secondarySystemBackground))
                
//                NativeAdView(nativeViewModel: nativeViewModel, style: .card)
//                    .frame(height: 380) // 250 ~ 300
//                    .background(Color(UIColor.secondarySystemBackground))
                    
            }
            .padding()
        }
        .background {
            // Add the adViewControllerRepresentable to the background so it
            // doesn't influence the placement of other views in the view hierarchy.
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
