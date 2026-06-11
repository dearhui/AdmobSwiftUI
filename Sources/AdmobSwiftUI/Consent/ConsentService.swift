//
//  ConsentService.swift
//  AdmobSwiftUI
//

import Foundation
import UIKit
import UserMessagingPlatform

/// Abstraction over the UMP SDK so `ConsentManager`'s state machine can be
/// unit-tested with a mock. The package always uses `UMPConsentService`;
/// tests inject their own implementation via `ConsentManager.init(service:)`.
@MainActor
protocol ConsentService: AnyObject {
    /// Current consent status, already mapped to the package's `ConsentStatus`.
    var consentStatus: ConsentStatus { get }

    /// Whether ads can be requested under the current consent state.
    var canRequestAds: Bool { get }

    /// Whether a privacy-options entry point must be offered to the user.
    var isPrivacyOptionsRequired: Bool { get }

    /// Requests a consent info update from the consent provider.
    func requestConsentInfoUpdate(
        tagForUnderAgeOfConsent: Bool,
        debugSettings: ConsentDebugSettings?
    ) async throws

    /// Loads and presents the consent form if the updated info requires one.
    func loadAndPresentConsentFormIfRequired(from viewController: UIViewController?) async throws

    /// Presents the privacy options form.
    func presentPrivacyOptionsForm(from viewController: UIViewController?) async throws

    /// Clears all persisted consent state.
    func reset()
}

/// Production `ConsentService` backed by the real UMP SDK.
@MainActor
final class UMPConsentService: ConsentService {

    var consentStatus: ConsentStatus {
        ConsentStatus(ConsentInformation.shared.consentStatus)
    }

    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    func requestConsentInfoUpdate(
        tagForUnderAgeOfConsent: Bool,
        debugSettings: ConsentDebugSettings?
    ) async throws {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = tagForUnderAgeOfConsent
        if let debugSettings {
            parameters.debugSettings = debugSettings.umpDebugSettings
        }
        try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
    }

    func loadAndPresentConsentFormIfRequired(from viewController: UIViewController?) async throws {
        try await ConsentForm.loadAndPresentIfRequired(from: viewController)
    }

    func presentPrivacyOptionsForm(from viewController: UIViewController?) async throws {
        try await ConsentForm.presentPrivacyOptionsForm(from: viewController)
    }

    func reset() {
        ConsentInformation.shared.reset()
    }
}
