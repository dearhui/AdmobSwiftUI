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
    
    init() {
        // 使用新的初始化方法，啟用調試模式
        let config = AdmobSwiftUI.Configuration(
            enableDebugMode: true  // 啟用測試廣告
        )
        AdmobSwiftUI.initialize(with: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
