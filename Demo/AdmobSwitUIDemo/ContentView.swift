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
                
                BannerView()
                    .frame(height: 50)
                    .background(Color.red)
                
                NativeAdView(nativeViewModel: nativeViewModel, style: .banner)
                    .frame(height: 80) // 250 ~ 300
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                    .onAppear {
                        nativeViewModel.refreshAd()
                    }
                
                NativeAdView(nativeViewModel: nativeViewModel, style: .card)
                    .frame(height: 300) // 250 ~ 300
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background {
            // Add the adViewControllerRepresentable to the background so it
            // doesn't influence the placement of other views in the view hierarchy.
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
