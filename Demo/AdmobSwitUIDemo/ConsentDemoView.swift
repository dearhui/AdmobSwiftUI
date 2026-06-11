//
//  ConsentDemoView.swift
//  AdmobSwitUIDemo
//
//  UMP 同意流程（GDPR）+ ATT 完整展示頁。
//  用 debug geography 強制 EEA，可重複走「reset → gather → 同意表單 → privacy options」流程。
//

import AdmobSwiftUI
import AppTrackingTransparency
import SwiftUI

struct ConsentDemoView: View {
    @ObservedObject private var consentManager = ConsentManager.shared

    @State private var attStatus: ATTrackingManager.AuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
    @State private var lastMessage = ""
    @State private var isWorking = false

    var body: some View {
        List {
            Section("目前狀態") {
                LabeledContent("consentStatus", value: String(describing: consentManager.consentStatus))
                LabeledContent("canRequestAds", value: consentManager.canRequestAds ? "true" : "false")
                LabeledContent("isPrivacyOptionsRequired", value: consentManager.isPrivacyOptionsRequired ? "true" : "false")
                LabeledContent("ATT status", value: attStatusDescription)
            }

            Section("同意流程") {
                Button("Gather Consent（模擬 EEA，必出表單）") {
                    run {
                        try await consentManager.gatherConsent(
                            debugSettings: ConsentDebugSettings(geography: .eea)
                        )
                        lastMessage = "EEA 流程完成，canRequestAds = \(consentManager.canRequestAds)"
                    }
                }

                Button("Gather Consent（真實地理位置）") {
                    run {
                        try await consentManager.gatherConsent()
                        lastMessage = "真實流程完成，canRequestAds = \(consentManager.canRequestAds)"
                    }
                }

                Button("Privacy Options（設定頁入口）") {
                    run {
                        try await consentManager.presentPrivacyOptionsForm()
                        lastMessage = "Privacy options 表單已關閉"
                    }
                }
                .disabled(!consentManager.isPrivacyOptionsRequired)
            }

            Section("ATT") {
                Button("Request Tracking Authorization") {
                    run {
                        attStatus = await consentManager.requestTrackingAuthorization()
                        lastMessage = "ATT status = \(attStatusDescription)"
                    }
                }
            }

            Section("Debug") {
                Button("Reset（清除同意狀態，重走流程）", role: .destructive) {
                    consentManager.reset()
                    lastMessage = "已 reset，可重新 gather"
                }

                Button("重新啟動 SDK（initialize gatherFirst）") {
                    run {
                        await AdmobSwiftUI.initialize(
                            with: AdmobSwiftUI.Configuration(enableDebugMode: true),
                            consentMode: .gatherFirst
                        )
                        lastMessage = "initialize 完成，isInitialized = \(AdmobSwiftUI.isInitialized)"
                    }
                }
            }

            if !lastMessage.isEmpty {
                Section("結果") {
                    Text(lastMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Consent (UMP + ATT)")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isWorking)
    }

    private var attStatusDescription: String {
        switch attStatus {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorized: return "authorized"
        @unknown default: return "unknown(\(attStatus.rawValue))"
        }
    }

    private func run(_ work: @escaping () async throws -> Void) {
        Task {
            isWorking = true
            defer { isWorking = false }
            do {
                try await work()
            } catch {
                lastMessage = "錯誤：\(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    NavigationStack {
        ConsentDemoView()
    }
}
