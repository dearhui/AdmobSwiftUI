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
        MobileAds.shared.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
