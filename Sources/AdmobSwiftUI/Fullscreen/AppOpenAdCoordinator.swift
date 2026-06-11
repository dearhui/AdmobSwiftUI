//
//  AppOpenAdCoordinator.swift
//  
//
//  Created by minghui on 2023/6/13.
//

@preconcurrency import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
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
        Task {
            do {
                let ad = try await GoogleMobileAds.AppOpenAd.load(with: adUnitID, request: GoogleMobileAds.Request())
                self.appOpenAd = ad
                self.loadTime = Date()
                ad.fullScreenContentDelegate = self
            } catch {
                AdmobSwiftUI.log("Failed to load app open ad: \(error.localizedDescription)", level: .error)
            }
        }
    }
    
    // MARK: - Async Ad Loading
    public typealias AdType = GoogleMobileAds.AppOpenAd
    
    public func loadAdAsync() async throws -> GoogleMobileAds.AppOpenAd {
        return try await loadAppOpenAd()
    }
    
    // MARK: - Async/await API
    public func loadAppOpenAd() async throws -> GoogleMobileAds.AppOpenAd {
        clean()

        let ad = try await GoogleMobileAds.AppOpenAd.load(with: adUnitID, request: GoogleMobileAds.Request())
        loadTime = Date()
        ad.fullScreenContentDelegate = self
        return ad
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
        return Date().timeIntervalSince(loadTime) > AdmobSwiftUI.Constants.appOpenAdExpirationInterval
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
        AdmobSwiftUI.log("Failed to present app open ad: \(error.localizedDescription)", level: .error)
        clean()
    }

    public func adWillPresentFullScreenContent(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        AdmobSwiftUI.log("App open ad will present", level: .debug)
    }

    public func adDidRecordImpression(_ ad: GoogleMobileAds.FullScreenPresentingAd) {
        AdmobSwiftUI.log("App open ad did record impression", level: .debug)
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