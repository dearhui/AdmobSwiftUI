//
//  NativeAdStylesView.swift
//  AdmobSwitUIDemo
//
//  v3 Native Ad 展示頁：四種內建 SwiftUI 模板 + 自訂 layout 範例。
//
//  注意：同一個 NativeAd 物件同時掛在多個 ad view 上時，SDK 只會把 media
//  渲染在最後關聯的那個（click 也歸它），所以這裡一次只顯示一種 style。
//

import SwiftUI
import AdmobSwiftUI

struct NativeAdStylesView: View {
    private enum Mode: String, CaseIterable, Identifiable {
        case banner, largeBanner, card, basic, custom
        var id: String { rawValue }

        var style: NativeAdViewStyle? {
            switch self {
            case .banner: return .banner
            case .largeBanner: return .largeBanner
            case .card: return .card
            case .basic: return .basic
            case .custom: return nil
            }
        }
    }

    @StateObject private var nativeViewModel = NativeAdViewModel(requestInterval: 60)
    @State private var mode: Mode = .banner

    var body: some View {
        VStack(spacing: 12) {
            Picker("Style", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let style = mode.style {
                        Text(".\(mode.rawValue)")
                            .font(.headline)
                        NativeAdView(nativeViewModel: nativeViewModel, style: style)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("AdmobNativeAdContainer 自訂 layout")
                            .font(.headline)
                        customLayout
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Native Ad Styles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Reload") {
                Task { try? await nativeViewModel.load() }
            }
        }
        .task {
            try? await nativeViewModel.load()
        }
    }

    @ViewBuilder
    private var customLayout: some View {
        if let ad = nativeViewModel.nativeAd {
            AdmobNativeAdContainer(ad: ad) { assets in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        assets.icon?
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            assets.headline
                                .font(.headline)
                                .lineLimit(1)
                            assets.advertiser
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        AdBadge(backgroundColor: .purple, cornerRadius: 6)
                    }

                    assets.media
                        .aspectRatio(assets.mediaAspectRatio, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    assets.body
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)

                    assets.callToAction
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.purple.gradient)
                        .cornerRadius(10)
                }
                .padding(12)
            }
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else {
            Text(nativeViewModel.isLoading ? "Loading ad..." : "No ad loaded")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        NativeAdStylesView()
    }
}
