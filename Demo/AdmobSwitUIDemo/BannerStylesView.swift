//
//  BannerStylesView.swift
//  AdmobSwitUIDemo
//
//  每種 banner style 一個分頁：anchored / inline / collapsible，
//  並顯示 onAdEvent 事件與實際 ad size，驗證高度回報。
//

import SwiftUI
import AdmobSwiftUI

struct BannerStylesView: View {
    enum StyleTab: String, CaseIterable, Identifiable {
        case anchored = "Anchored"
        case inline = "Inline"
        case collapsible = "Collapsible"
        var id: String { rawValue }
    }

    @State private var tab: StyleTab = .anchored
    @State private var events: [String] = []
    @State private var adSize: CGSize?

    var body: some View {
        VStack(spacing: 0) {
            Picker("Style", selection: $tab) {
                ForEach(StyleTab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch tab {
            case .anchored: anchoredDemo
            case .inline: inlineDemo
            case .collapsible: collapsibleDemo
            }
        }
        .navigationTitle("Banner Styles")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tab) { _ in
            events = []
            adSize = nil
        }
    }

    // MARK: - Tabs

    /// Anchored：不加外部 frame，驗證 BannerView 會自己保留正確高度。
    private var anchoredDemo: some View {
        VStack {
            eventLog
            Spacer()
            Text("⬇️ BannerView(style: .anchored)，無外部 frame")
                .font(.caption)
                .foregroundColor(.secondary)
            BannerView(style: .anchored, onAdEvent: handle)
                .background(Color.red.opacity(0.15))
                .id(StyleTab.anchored)
        }
    }

    /// Inline：嵌在滾動列表中，高度在載入後由 didReceive 撐開。
    private var inlineDemo: some View {
        List {
            Section { eventLog }
            ForEach(1..<6) { i in
                Text("List row \(i)")
            }
            BannerView(style: .inline, onAdEvent: handle)
                .background(Color.blue.opacity(0.15))
                .id(StyleTab.inline)
                .listRowInsets(EdgeInsets())
            ForEach(6..<20) { i in
                Text("List row \(i)")
            }
        }
        .listStyle(.plain)
    }

    /// Collapsible：錨定在畫面底部，載入後先展開大版位、再收合成一般 anchored。
    private var collapsibleDemo: some View {
        VStack {
            eventLog
            Spacer()
            Text("⬇️ BannerView(style: .collapsible(placement: .bottom))")
                .font(.caption)
                .foregroundColor(.secondary)
            BannerView(style: .collapsible(placement: .bottom), onAdEvent: handle)
                .background(Color.green.opacity(0.15))
                .id(StyleTab.collapsible)
        }
    }

    // MARK: - Event log

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ad size: \(adSize.map { "\(Int($0.width)) x \(Int($0.height))" } ?? "—")")
                .font(.footnote.bold())
            ForEach(Array(events.suffix(8).enumerated()), id: \.offset) { _, event in
                Text(event)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private func handle(_ event: BannerAdEvent) {
        switch event {
        case .didReceive(let size):
            adSize = size
            events.append("didReceive \(Int(size.width)) x \(Int(size.height))")
        case .didFailToReceive(let error):
            events.append("didFail: \(error.localizedDescription)")
        case .didRecordImpression:
            events.append("didRecordImpression")
        case .didRecordClick:
            events.append("didRecordClick")
        case .willPresentScreen:
            events.append("willPresentScreen")
        case .willDismissScreen:
            events.append("willDismissScreen")
        case .didDismissScreen:
            events.append("didDismissScreen")
        }
    }
}

struct BannerStylesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BannerStylesView()
        }
    }
}
