//
//  AdmobSwitUIDemoApp.swift
//  AdmobSwitUIDemo
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import GoogleMobileAds

@main
struct AdmobSwitUIDemoApp: App {
    
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
