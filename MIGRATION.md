# AdmobSwiftUI 3.0 遷移指南

本指南涵蓋兩條升級路徑：

- [v2.x → v3.0](#v2x--v30)：所有 v2 API 在 v3 仍可編譯（標記 deprecated，**4.0 移除**），可以漸進遷移。
- [v1.2.3 → v3.0](#v123--v30)：v1 的 API 簽名已不存在，需要一次性改寫；本章提供逐 API 對照。

## 環境需求變更

| | v1.2.3 | v2.x | v3.0 |
|---|---|---|---|
| iOS | 14.0+ | 14.0+ | **15.0+** |
| Google Mobile Ads SDK | 10.x | 12.9+ | **13.5+** |
| UserMessagingPlatform（UMP） | — | — | **3.0+（新依賴，自動帶入）** |
| Xcode | 14+ | 16+ | 16+ |
| Swift concurrency | — | 部分 | **全面 Swift 6 language mode、主要型別 @MainActor** |

---

# v2.x → v3.0

## 1. 初始化：改為 async 並整合 UMP 同意流程

v3 的初始化是 `async`，預設（`.gatherFirst`）會先跑完 UMP 同意流程（GDPR 等），確認 `canRequestAds` 後才啟動 Mobile Ads SDK：

```swift
// v2（deprecated）
init() {
    AdmobSwiftUI.initialize()
}

// v3
WindowGroup {
    ContentView()
        .task {
            await AdmobSwiftUI.initialize()   // 預設 consentMode: .gatherFirst
            // Google 建議：UMP 流程完成後再請求 ATT
            await ConsentManager.shared.requestTrackingAuthorization()
        }
}
```

- 不想讓套件處理同意流程，傳 `consentMode: .manual`，行為等同 v2（立即啟動 SDK），再自行操作 `ConsentManager`。
- 同意流程失敗（如網路錯誤）不會卡死啟動：只要前一個 session 已確立 `canRequestAds`，SDK 照常啟動。
- 歐盟使用者需要「隱私選項」入口：`ConsentManager.shared.isPrivacyOptionsRequired` 為 `true` 時，在設定頁提供按鈕呼叫 `presentPrivacyOptionsForm()`。
- ATT 需要在 Info.plist 加 `NSUserTrackingUsageDescription`。

## 2. 全螢幕廣告 Coordinator：統一 async/await API

三個 coordinator 改為 `@MainActor` + `ObservableObject`，統一 `adState` / `isReady` / `load()` / `present(from:)` / `loadAndPresent(from:)` 介面（`FullScreenAdCoordinator` protocol；Rewarded 形狀相同但 `present` 會回傳獎勵）。

### InterstitialAdCoordinator

| v2（deprecated，4.0 移除） | v3 |
|---|---|
| `loadAd()` | `try await load()` |
| `showAd(from:)` | `try present(from:)` |
| `let ad = try await loadInterstitialAd()`<br>`ad.present(from: vc)` | `try await loadAndPresent(from: vc)` |

### AppOpenAdCoordinator

| v2（deprecated，4.0 移除） | v3 |
|---|---|
| `isAdAvailable` | `isReady`（會檢查 4 小時過期） |
| `loadAd()` | `try await load()` |
| `showAd(from:)` | `try present(from:)` 或 `presentIfAvailable(from:)` |
| `loadAppOpenAd()` / `loadAdAsync()` | `load()` + `present(from:)` |
| 手寫 scenePhase 補載邏輯 | `autoReloadsOnForeground = true` + `presentIfAvailable()` |

典型 App Open 流程在 v3 簡化為：

```swift
@Environment(\.scenePhase) private var scenePhase
@StateObject private var appOpenCoordinator = AppOpenAdCoordinator()

var body: some View {
    ContentView()
        .onAppear { appOpenCoordinator.autoReloadsOnForeground = true }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                appOpenCoordinator.presentIfAvailable()   // 沒廣告就自動補載，不丟錯
            }
        }
}
```

### RewardedAdCoordinator

`present(from:)` 會 **suspend 到使用者看完並獲得獎勵**，直接回傳 `AdReward`；中途關閉丟 `AdmobSwiftUIError.rewardNotEarned`：

```swift
// v2（deprecated）
let ad = try await rewardCoordinator.loadRewardedAd()
rewardCoordinator.showAd(from: vc) { amount in
    grantCoins(amount)
}

// v3
let reward = try await rewardCoordinator.loadAndPresent(from: vc)
grantCoins(reward.amount)   // reward.type 是 ad unit 設定的獎勵類型
```

| v2（deprecated，4.0 移除） | v3 |
|---|---|
| `init(adUnitID:InterstitialID:)` | `init(adUnitID:interstitialAdUnitID:)` |
| `loadAd()` | `try await load()`（預設 `.rewarded`） |
| `loadRewardedAd()` | `try await load(.rewarded)` |
| `loadInterstitialAd()` | `try await load(.rewardedInterstitial)` |
| `showAd(from:userDidEarnRewardHandler:)` | `let reward = try await present(from:)` |

### Protocol

`AdCoordinatorProtocol` / `AsyncAdCoordinatorProtocol` 整組 deprecated，改用 `FullScreenAdCoordinator`。

## 3. Banner：高度自動，移除外部 frame

```swift
// v2
BannerView()
    .frame(height: 50)        // ⚠️ v3 請移除

// v3
BannerView()                  // 高度自動保留與更新
```

- **高度自動**：anchored 樣式在量到寬度時就保留正確高度（廣告載入前），載入後更新為實際高度。**保留外部 `.frame(height:)` 會切掉或壓縮廣告。**
- **anchored 高度變大**：v3 改用 large anchored adaptive banner（支援 video demand），高度依寬度為 50–150pt——iPhone 直向實測約 116pt，不再是固定 50pt。版面預留空間要重新檢視。
- **inline 高度**：載入後才確定，想知道實際值監聽 `BannerAdEvent.didReceive(adSize:)`。
- 新增 **`.collapsible(placement: .top/.bottom)`** 樣式（可收合橫幅；注意 [Google 政策](https://support.google.com/admob/answer/14076373)有展示頻率等限制）。
- 新增 **`onAdEvent`** 事件 closure：

```swift
BannerView(style: .inline) { event in
    switch event {
    case .didReceive(let adSize): print("loaded \(adSize)")
    case .didFailToReceive(let error): print(error)
    default: break
    }
}
```

## 4. Native Ads：模板全面 SwiftUI 化 + 自訂 Layout API

`NativeAdView(nativeViewModel:style:)` 的 init 不變，但行為有三個差異：

1. **無廣告時不渲染任何東西**（v2 會渲染空模板骨架）。需要佔位請自行用 `if nativeViewModel.nativeAd == nil` 包 placeholder。
2. **高度自動**：移除外部 `.frame(height:)`，保留反而會壓縮內容。
3. **`.basic` 樣式由 XIB 轉為 SwiftUI**：整體佈局等價，但有像素級差異。

```swift
// v2
NativeAdView(nativeViewModel: vm, style: .card)
    .frame(height: 300)       // ⚠️ v3 請移除
vm.refreshAd()                 // deprecated

// v3
NativeAdView(nativeViewModel: vm, style: .card)
try await vm.load()            // async，失敗會丟錯
```

**自訂版面**改用新的 `AdmobNativeAdContainer` + `NativeAdAssets`，所有元件預綁 click attribution：

```swift
AdmobNativeAdContainer(ad: nativeAd) { assets in
    VStack(alignment: .leading) {
        HStack {
            assets.icon?.frame(width: 40, height: 40)
            assets.headline.font(.headline)
            AdBadge()
        }
        assets.media.aspectRatio(assets.mediaAspectRatio, contentMode: .fit)
        assets.callToAction?
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
    }
}
```

注意：

- `assets.callToAction` **不是 `Button`**——點擊由 SDK 接管計費，只需把它造型成按鈕的樣子。
- `assets.icon` 已是 `resizable`，用 `.frame` + `.aspectRatio(contentMode:)` 控制尺寸。
- 用自己的 view 渲染原始資料（`assets.ad.headline` 等）時，套 `.nativeAdAsset(.headline)` 標記，否則點擊不會被歸因。
- **同一個 `NativeAd` 物件同時掛到多個 view 時，media 與點擊只歸最後關聯的那個**（SDK 行為）——一個畫面一次只顯示一種樣式。
- 移除（無替代）：XIB 與 UIKit 佈局 helpers（`stack`/`hstack`/`withWidth` 等，原 internal API）。

## 5. 錯誤型別新增 cases

`AdmobSwiftUIError` 新增 `adExpired`、`invalidConfiguration`、`rewardNotEarned`、`consentGatheringFailed`。對它做 exhaustive `switch` 的程式碼需要補上新 cases。

## 6. Swift 6 / @MainActor

`InterstitialAdCoordinator`、`AppOpenAdCoordinator`、`RewardedAdCoordinator`、`NativeAdViewModel`、`ConsentManager` 都標了 `@MainActor`。從非主執行緒呼叫的舊程式碼（多半本來就有 bug）在 Swift 6 mode 下會編譯錯誤；SwiftUI view / `@StateObject` 內使用不受影響。

---

# v1.2.3 → v3.0

> 這條路徑沒有相容 shim，以下 API 全部需要改寫。改寫量不大——v1 的功能面 v3 都有、且更簡單。

## 1. 初始化

```swift
// v1：直接呼叫 GMA SDK
GADMobileAds.sharedInstance().start(completionHandler: nil)

// v3
await AdmobSwiftUI.initialize()
await ConsentManager.shared.requestTrackingAuthorization()
```

## 2. InterstitialAdCoordinator 拆分

v1 的 `InterstitialAdCoordinator` 同時管 interstitial 和 App Open 兩種廣告；v3 拆成兩個 coordinator：

```swift
// v1
private let adCoordinator = InterstitialAdCoordinator(
    appOpenadUnitID: "ca-app-pub-.../5662855259",
    adUnitID: "ca-app-pub-.../4411468910"
)

// v3：一拆為二
@StateObject private var interstitialCoordinator = InterstitialAdCoordinator(adUnitID: "ca-app-pub-.../4411468910")
@StateObject private var appOpenCoordinator = AppOpenAdCoordinator(adUnitID: "ca-app-pub-.../5662855259")
```

逐 API 對照：

| v1.2.3 | v3 |
|---|---|
| `InterstitialAdCoordinator(appOpenadUnitID:adUnitID:)` | `InterstitialAdCoordinator(adUnitID:)` + `AppOpenAdCoordinator(adUnitID:)` |
| `loadAd()`（fire-and-forget、失敗無聲） | `try await load()` |
| `showAd(from:)`（沒廣告只印 log） | `try present(from:)`（丟 `adNotLoaded`） |
| `let ad = try await loadInterstitialAd()`<br>`ad.present(fromRootViewController: vc)` | `try await interstitialCoordinator.loadAndPresent(from: vc)` |
| `let ad = try await loadAppOpenAd()`<br>`ad.present(fromRootViewController: vc)` | `try await appOpenCoordinator.loadAndPresent(from: vc)`；scenePhase 場景改用 `autoReloadsOnForeground` + `presentIfAvailable()`（見上方 v2→v3 範例） |

v3 的 App Open 多了 4 小時過期檢查（Google 政策）：過期的廣告 `isReady == false`、`present` 丟 `adExpired`，不會像 v1 一樣把過期廣告呈現出去。

## 3. RewardedAdCoordinator

| v1.2.3 | v3 |
|---|---|
| `init(adUnitID:InterstitialID:)` | `init(adUnitID:interstitialAdUnitID:)`（參數改名） |
| `loadAd()` | `try await load()` |
| `loadRewardedAd()` + `showAd(from:userDidEarnRewardHandler:)` | `let reward = try await loadAndPresent(from: vc)` |
| `loadInterstitialAd()`（rewarded interstitial） | `try await load(.rewardedInterstitial)` + `present(from:)` |
| handler 收 `Int`（amount） | `AdReward` struct（`amount: Int` + `type: String`） |

```swift
// v1
let ad = try await rewardCoordinator.loadRewardedAd()
rewardCoordinator.showAd(from: vc) { amount in
    grantCoins(amount)
}

// v3
let reward = try await rewardCoordinator.loadAndPresent(from: vc)
grantCoins(reward.amount)
```

## 4. BannerView

| v1.2.3 | v3 |
|---|---|
| `BannerView(adUnitID:)` + 外部 `.frame(height: 50)` | `BannerView(adUnitID:)`，**移除外部 frame**，高度自動 |
| 固定 anchored adaptive（~50pt） | large anchored adaptive（50–150pt，iPhone 直向約 116pt）；另有 `.inline`、`.collapsible` 樣式 |
| 無事件回呼 | `onAdEvent` closure（載入成功/失敗、曝光、點擊） |

## 5. NativeAdViewModel / NativeAdView

| v1.2.3 | v3 |
|---|---|
| `refreshAd()`（fire-and-forget） | `try await load()` |
| `nativeAd: GADNativeAd?` | `nativeAd: NativeAd?`（SDK 13 拿掉 GAD 前綴） |
| `NativeAdView(nativeViewModel:style:)` + 外部 frame | 同名 init，**移除外部 frame**；無廣告時不渲染（v1/v2 渲染空骨架） |

## 6. 廣告 ID 管理

v1 時代 hardcode 的測試 ID 建議改用 `AdmobSwiftUI.AdUnitIDs`（DEBUG 自動用測試 ID、RELEASE 用正式 ID），或至少繼續以參數傳入正式 ID——v3 所有 init 的預設值都是 `AdUnitIDs` 系列。

## 7. 順帶：GMA SDK 13 的型別改名

如果 App 內有直接使用 GMA SDK 型別，SDK 10 → 13 把 `GAD` 前綴拿掉了：`GADInterstitialAd` → `InterstitialAd`、`GADRequest` → `Request`、`present(fromRootViewController:)` → `present(from:)` 等。完整對照見 [Google 官方 SDK 13 遷移文件](https://developers.google.com/admob/ios/migration)。多數情況下改用 AdmobSwiftUI 的 coordinator API 後就不需要直接碰 SDK 型別了。

---

## 快速檢查清單

- [ ] 最低版本升到 iOS 15
- [ ] 初始化改 `await AdmobSwiftUI.initialize()`（放 `.task`），之後請求 ATT
- [ ] Info.plist：確認 `GADApplicationIdentifier`，新增 `NSUserTrackingUsageDescription`
- [ ] 歐盟隱私選項入口：`isPrivacyOptionsRequired` 時提供 `presentPrivacyOptionsForm()`
- [ ] 移除 `BannerView` / `NativeAdView` 的外部 `.frame(height:)`
- [ ] 檢視 banner 版面：anchored 高度可能從 50pt 變 ~116pt
- [ ] Rewarded 改用 `present(from:)` 回傳的 `AdReward`
- [ ] App Open 改 `autoReloadsOnForeground` + `presentIfAvailable()`
- [ ] `AdmobSwiftUIError` 的 exhaustive switch 補新 cases
- [ ] 編譯後處理所有 deprecation warning（這些 API 4.0 會移除）
