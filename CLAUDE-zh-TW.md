# CLAUDE-zh-TW.md

此檔案為 Claude Code (claude.ai/code) 在此儲存庫中工作時的繁體中文指南。

## 專案概述

AdmobSwiftUI 是一個將 Google AdMob 廣告整合到 SwiftUI 應用程式中的 Swift 套件。支援多種廣告格式：橫幅廣告、插頁廣告、應用程式開啟廣告、獎勵廣告、獎勵插頁廣告和原生廣告。

## 建置指令

這是一個僅適用於 iOS 的 Swift 套件，目標為 iOS 14.0+。由於 LBTATools 依賴項需要 UIKit，該套件目前在 macOS 上存在建置問題。

- **為 iOS 建置**：使用 Xcode 或從 iOS 裝置/模擬器環境建置
- **測試**：`swift test`（目前在 macOS 上失敗，需要 iOS 環境）
- **示範專案**：在 Xcode 中開啟並執行 `Demo/AdmobSwitUIDemo.xcodeproj`

## 架構

### 核心元件

- **橫幅廣告**：`BannerView.swift` 和 `BannerViewController.swift` - GADBannerView 的 SwiftUI 包裝器
- **全螢幕廣告**：`Fullscreen/` 目錄中的插頁廣告、獎勵廣告和應用程式開啟廣告協調器
- **原生廣告**：`Native/` 目錄中具有多種檢視樣式的完整原生廣告實作
- **AdViewControllerRepresentable**：從 SwiftUI 呈現全螢幕廣告的橋接器

### 目錄結構

```
Sources/AdmobSwiftUI/
├── AdmobSwiftUI.swift          # 套件進入點
├── Banner/                     # 橫幅廣告元件
├── Fullscreen/                 # 插頁、獎勵、應用程式開啟廣告
├── Native/                     # 原生廣告檢視和檢視模型
├── Extensions/                 # UIColor 擴充功能
└── Resources/                  # XIB 檔案、素材、本地化
```

### 主要依賴項

- Google Mobile Ads SDK (11.2.0+)
- LBTATools 用於 UI 工具
- iOS 14.0+ 需求

### 廣告實作模式

1. 在 App delegate 中初始化 Google Mobile Ads：`GADMobileAds.sharedInstance().start(completionHandler: nil)`
2. 使用協調器處理全螢幕廣告（async/await 模式）
3. 直接使用 SwiftUI 檢視處理橫幅和原生廣告
4. 在檢視階層中包含 `AdViewControllerRepresentable` 用於全螢幕廣告呈現

### 資源處理

套件包含應在 Package.swift 中宣告的未處理資源：
- 原生廣告佈局的 XIB 檔案
- 素材目錄
- 本地化檔案
- Info.plist 檔案

### 設定需求

- 在建置設定的「其他連結器標誌」中新增 `-ObjC` 標誌
- 使用 Google Mobile Ads 需求設定 Info.plist
- 在應用程式啟動時初始化 GADMobileAds