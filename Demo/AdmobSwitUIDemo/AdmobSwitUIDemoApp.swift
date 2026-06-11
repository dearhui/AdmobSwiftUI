//
//  AdmobSwitUIDemoApp.swift
//  AdmobSwitUIDemo
//
//  Created by minghui on 2023/6/13.
//

import SwiftUI
import AdmobSwiftUI

@main
struct AdmobSwitUIDemoApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // v3 async 初始化：先跑 UMP 同意流程，canRequestAds 後才啟動 SDK。
                    // 想完整體驗 EEA 同意表單流程，請進「Consent (UMP + ATT)」頁面。
                    let config = AdmobSwiftUI.Configuration(
                        enableDebugMode: true  // 啟用測試廣告
                    )
                    await AdmobSwiftUI.initialize(with: config, consentMode: .gatherFirst)
                    // Google 建議：UMP 流程完成後再請求 ATT
                    await ConsentManager.shared.requestTrackingAuthorization()
                }
        }
    }
}
