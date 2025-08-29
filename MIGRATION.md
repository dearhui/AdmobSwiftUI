# AdmobSwiftUI v1.0.0 遷移指南

本指南幫助現有使用者從舊版本升級到 v1.0.0，瞭解破壞性變更和遷移步驟。

## 🚨 破壞性變更概覽

### 1. 初始化方法變更
### 2. 錯誤處理改進  
### 3. LBTATools 依賴移除
### 4. 資源打包修復

---

## 📋 逐步遷移指南

### 步驟 1: 更新初始化代碼

**舊版本 (< v1.0.0):**
```swift
@main
struct YourApp: App {
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**新版本 (v1.0.0+):**
```swift
import AdmobSwiftUI  // 新增這行

@main
struct YourApp: App {
    init() {
        // 推薦方式
        AdmobSwiftUI.initialize()
        
        // 或使用自訂配置
        let config = AdmobSwiftUI.Configuration(
            testDeviceIdentifiers: ["your-device-id"],
            enableDebugMode: true
        )
        AdmobSwiftUI.initialize(with: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**過渡方案 (暫時兼容):**
```swift
// 如果暫時無法修改，可以保持舊代碼不變
// AdmobSwiftUI 會自動檢測並適應
GADMobileAds.sharedInstance().start(completionHandler: nil)
```

### 步驟 2: 更新錯誤處理

**舊版本:**
```swift
Button("Show Interstitial") {
    // 可能會 crash 或只印出錯誤
    adCoordinator.showAd(from: viewController)
}
```

**新版本 - 推薦方式:**
```swift
Button("Show Interstitial") {
    do {
        try adCoordinator.showAd(from: viewController)
    } catch let error as AdmobSwiftUIError {
        switch error {
        case .adNotLoaded:
            print("廣告尚未載入，請先載入廣告")
        case .sdkNotInitialized:
            print("SDK 未初始化，請檢查初始化代碼")
        case .adLoadFailed(let originalError):
            print("廣告載入失敗: \(originalError.localizedDescription)")
        case .presentationFailed(let reason):
            print("廣告顯示失敗: \(reason)")
        }
    } catch {
        print("未預期的錯誤: \(error)")
    }
}
```

**過渡方案 - 使用舊版 API (已標記為 deprecated):**
```swift
Button("Show Interstitial") {
    // 使用 Legacy 方法，會自動處理錯誤但會顯示 deprecation 警告
    adCoordinator.showAdLegacy(from: viewController)
}
```

### 步驟 3: 處理 LBTATools 依賴移除

如果你的專案其他地方也使用 LBTATools，有兩種選擇：

**選擇 A: 繼續使用 LBTATools (推薦)**
```swift
// 在你的 Package.swift 或 Podfile 中單獨添加 LBTATools
// AdmobSwiftUI 不再需要它，但你的代碼可以繼續使用
```

**選擇 B: 遷移到原生 UIKit**
```swift
// 舊代碼
let stackView = hstack(label1, label2, spacing: 8)

// 新代碼
let stackView = UIStackView(arrangedSubviews: [label1, label2])
stackView.axis = .horizontal
stackView.spacing = 8
```

### 步驟 4: 驗證資源載入

新版本修復了資源打包問題，XIB 和圖片資源現在會正確載入。如果之前有資源載入問題，現在應該已經解決。

---

## ⚡ 快速遷移檢查清單

- [ ] 更新 App 初始化代碼
- [ ] 添加 `import AdmobSwiftUI`
- [ ] 更新廣告顯示的錯誤處理
- [ ] 測試所有廣告類型是否正常工作
- [ ] 檢查是否有 LBTATools 相關編譯錯誤
- [ ] 驗證原生廣告資源是否正確載入

---

## 🔄 漸進式遷移策略

### 階段 1: 最小變更 (立即可行)
1. 保持現有初始化代碼不變
2. AdmobSwiftUI 會自動適應
3. 暫時忽略 deprecation 警告

### 階段 2: 改善錯誤處理 (1-2 週內)
1. 更新關鍵廣告顯示邏輯使用新的錯誤處理
2. 逐步替換 `showAdLegacy` 為 `showAd`

### 階段 3: 完整遷移 (下個版本發布前)
1. 更新初始化方法為 `AdmobSwiftUI.initialize()`
2. 移除所有 deprecated 方法的使用
3. 添加適當的配置選項

---

## 🆘 常見問題

### Q: 升級後出現編譯錯誤怎麼辦？
A: 最常見的是 LBTATools 相關錯誤。解決方案：
1. 檢查是否有其他地方使用 LBTATools
2. 如有需要，單獨添加 LBTATools 依賴
3. 或者遷移相關代碼到原生 UIKit

### Q: 我的廣告不再顯示了？
A: 檢查以下項目：
1. 是否正確初始化了 AdmobSwiftUI
2. 錯誤處理是否捕獲了具體錯誤信息
3. 使用 `AdmobSwiftUI.isInitialized` 檢查初始化狀態

### Q: 可以逐步遷移嗎？
A: 是的！新版本提供向後相容性：
1. 繼續使用舊的初始化方法
2. 使用 `showAdLegacy` 方法暫時避免錯誤處理更改
3. 逐步更新到新 API

### Q: 新版本有什麼好處？
A: 主要改善：
1. 🚫 不再有 macOS 建置問題 (移除 LBTATools)
2. 🔧 更好的錯誤處理和除錯信息
3. 📦 修復了資源打包問題
4. 🧪 完整的單元測試覆蓋
5. 📚 詳細的文檔和範例

---

## 📞 需要幫助？

如果在遷移過程中遇到問題：
1. 查看 [README.md](README.md) 的完整範例
2. 檢查單元測試文件瞭解正確用法
3. 在 GitHub Issues 中回報問題

**記住：可以逐步遷移，不需要一次性修改所有代碼！**