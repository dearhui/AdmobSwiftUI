//
//  AppOpenAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

import GoogleMobileAds
import SwiftUI
import UIKit

public class AppOpenAdCoordinator: NSObject, GoogleMobileAds.FullScreenContentDelegate {
    private var appOpenAd: GoogleMobileAds.AppOpenAd?
    private let adUnitID: String
    private var loadTime: Date?
    
    public init(adUnitID: String = AdmobSwiftUI.AdUnitIDs.appOpen) {
        // Validate ad unit ID
        guard !adUnitID.isEmpty else {
            fatalError("AdmobSwiftUI: Ad unit ID cannot be empty")
        }
        
        if adUnitID.hasPrefix("your-") {
            AdmobSwiftUI.log("Warning: Using placeholder ad unit ID. Replace with your actual ad unit ID before release.", level: .warning)
        }
        
        self.adUnitID = adUnitID
        super.init()
    }
    
    // MARK: - Ad Loading
    public func loadAd() {
        clean()
        GoogleMobileAds.AppOpenAd.load(with: adUnitID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
            if let ad = ad {
                self.appOpenAd = ad
                self.loadTime = Date()
                ad.fullScreenContentDelegate = self
            } else {
                print("Failed to load app open ad: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
    }
    
    // MARK: - Async Ad Loading
    public typealias AdType = GoogleMobileAds.AppOpenAd
    
    public func loadAdAsync() async throws -> GoogleMobileAds.AppOpenAd {
        return try await loadAppOpenAd()
    }
    
    // MARK: - Async/await API
    public func loadAppOpenAd() async throws -> GoogleMobileAds.AppOpenAd {
        clean()
        
        return try await withCheckedThrowingContinuation { continuation in
            GoogleMobileAds.AppOpenAd.load(with: adUnitID, request: GoogleMobileAds.Request(), completionHandler: { ad, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let ad = ad {
                    self.loadTime = Date()
                    ad.fullScreenContentDelegate = self
                    continuation.resume(returning: ad)
                }
            })
        }
    }
    
    // MARK: - Ad Presentation
    public func showAd(from viewController: UIViewController) throws {
        guard let appOpenAd = appOpenAd else {
            throw AdmobSwiftUIError.adNotLoaded
        }
        
        guard !isAdExpired else {
            throw AdmobSwiftUIError.adExpired
        }
        
        appOpenAd.present(from: viewController)
    }
    
    // MARK: - Ad State Management
    public var isAdAvailable: Bool {
        return appOpenAd != nil && !isAdExpired
    }
    
    private var isAdExpired: Bool {
        guard let loadTime = loadTime else { return true }
        // App open ads expire after 4 hours
        return Date().timeIntervalSince(loadTime) > 4 * 60 * 60
    }
    
    private func clean() {
        appOpenAd?.fullScreenContentDelegate = nil
        appOpenAd = nil
        loadTime = nil
    }
    
    // MARK: - GADFullScreenContentDelegate methods
    public func adDidDismissFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        clean()
    }
    
    public func ad(_ ad: GoogleMobileAds.FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present app open ad: \(error.localizedDescription)")
        clean()
    }
    
    public func adWillPresentFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        print("App open ad will present")
    }
    
    public func adDidRecordImpression(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        print("App open ad did record impression")
    }
}

// MARK: - Usage Example
/*
struct ContentView: View {
    private let adViewControllerRepresentable = AdViewControllerRepresentable()
    private let appOpenAdCoordinator = AppOpenAdCoordinator()
    
    var body: some View {
        VStack {
            Text("App Content")
            
            Button("Load App Open Ad") {
                appOpenAdCoordinator.loadAd()
            }
            
            Button("Show App Open Ad") {
                appOpenAdCoordinator.showAd(from: adViewControllerRepresentable.viewController)
            }
        }
        .background {
            // Add the adViewControllerRepresentable to the background
            adViewControllerRepresentable
                .frame(width: .zero, height: .zero)
        }
        .onAppear {
            // Typically load app open ad when app becomes active
            appOpenAdCoordinator.loadAd()
        }
    }
}

// For app lifecycle management
class AppDelegate: UIResponder, UIApplicationDelegate {
    let appOpenAdCoordinator = AppOpenAdCoordinator()
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Show app open ad when app becomes active
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            appOpenAdCoordinator.showAd(from: rootViewController)
        }
    }
}
*/