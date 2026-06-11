import AppTrackingTransparency
import Foundation
import UIKit
import UserMessagingPlatform

// MARK: - Public Types

/// The user's consent status, mirroring UMP's `ConsentInformation.consentStatus`.
public enum ConsentStatus: Sendable, Equatable {
    /// Consent status is unknown; `gatherConsent` has not completed yet.
    case unknown
    /// Consent is required but has not been obtained.
    case required
    /// Consent is not required (e.g. user outside a regulated region).
    case notRequired
    /// Consent has been obtained from the user.
    case obtained

    init(_ status: UserMessagingPlatform.ConsentStatus) {
        switch status {
        case .required: self = .required
        case .notRequired: self = .notRequired
        case .obtained: self = .obtained
        case .unknown: self = .unknown
        @unknown default: self = .unknown
        }
    }
}

/// How `AdmobSwiftUI.initialize(with:consentMode:)` handles consent before starting the SDK.
public enum ConsentMode: Sendable, Equatable {
    /// Run the full UMP consent flow first; the Mobile Ads SDK starts only once
    /// `ConsentManager.shared.canRequestAds` is `true`.
    case gatherFirst
    /// Skip consent handling and start the SDK immediately.
    /// The app is responsible for driving `ConsentManager` itself.
    case manual
}

/// Debug overrides for testing consent flows (e.g. simulating an EEA user).
///
/// Debug features are always enabled for simulators; physical devices must be
/// listed in `testDeviceIdentifiers` (the device's UMP hashed ID is printed to
/// the console on the first consent request).
public struct ConsentDebugSettings: Sendable, Equatable {
    /// Simulated geography for consent testing.
    public enum Geography: Sendable, Equatable {
        /// No geography override.
        case disabled
        /// Device appears as if located in the EEA (GDPR applies).
        case eea
        /// Device appears as if located in a regulated US state.
        case regulatedUSState
        /// Device appears as if located in a region with no regulation in force.
        case other
    }

    public var geography: Geography
    public var testDeviceIdentifiers: [String]

    public init(geography: Geography = .disabled, testDeviceIdentifiers: [String] = []) {
        self.geography = geography
        self.testDeviceIdentifiers = testDeviceIdentifiers
    }

    var umpDebugSettings: DebugSettings {
        let settings = DebugSettings()
        settings.testDeviceIdentifiers = testDeviceIdentifiers
        switch geography {
        case .disabled: settings.geography = .disabled
        case .eea: settings.geography = .EEA
        case .regulatedUSState: settings.geography = .regulatedUSState
        case .other: settings.geography = .other
        }
        return settings
    }
}

// MARK: - ConsentManager

/// Manages the UMP (User Messaging Platform) consent flow for GDPR and other
/// privacy regulations, plus the App Tracking Transparency prompt.
///
/// Typical usage:
/// ```swift
/// // At app startup (handled automatically by `AdmobSwiftUI.initialize(consentMode: .gatherFirst)`):
/// try await ConsentManager.shared.gatherConsent()
/// await ConsentManager.shared.requestTrackingAuthorization()
///
/// // In Settings, when `isPrivacyOptionsRequired` is true:
/// try await ConsentManager.shared.presentPrivacyOptionsForm()
/// ```
@MainActor
public final class ConsentManager: ObservableObject {

    public static let shared = ConsentManager()

    /// The user's current consent status. Updated after every consent operation.
    @Published public private(set) var consentStatus: ConsentStatus = .unknown

    /// Whether ads can be requested. `true` once consent has been gathered
    /// (or determined unnecessary), including values persisted from a previous session.
    public var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    /// Whether the app must offer the user an entry point (e.g. in Settings)
    /// to modify their privacy options.
    public var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private init() {
        consentStatus = ConsentStatus(ConsentInformation.shared.consentStatus)
    }

    /// Runs the full UMP consent flow: requests a consent info update, then
    /// automatically presents the consent form if one is required.
    ///
    /// Call this once per app session before loading ads. If the user already
    /// made a choice in a previous session, no form is shown.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present the consent form from.
    ///     Pass `nil` (default) to let UMP find the top view controller.
    ///   - debugSettings: Optional debug overrides, e.g. to simulate an EEA user.
    ///   - tagForUnderAgeOfConsent: Whether the user is tagged as under the age of consent.
    /// - Throws: `AdmobSwiftUIError.consentGatheringFailed` if the consent info
    ///   update or form presentation fails (e.g. network error).
    public func gatherConsent(
        from viewController: UIViewController? = nil,
        debugSettings: ConsentDebugSettings? = nil,
        tagForUnderAgeOfConsent: Bool = false
    ) async throws {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = tagForUnderAgeOfConsent
        if let debugSettings {
            parameters.debugSettings = debugSettings.umpDebugSettings
        }

        defer { syncStatus() }
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            syncStatus()
            try await ConsentForm.loadAndPresentIfRequired(from: viewController)
            AdmobSwiftUI.log("Consent gathered. status=\(consentStatus), canRequestAds=\(canRequestAds)", level: .info)
        } catch {
            AdmobSwiftUI.log("Consent gathering failed: \(error.localizedDescription)", level: .error)
            throw AdmobSwiftUIError.consentGatheringFailed(error)
        }
    }

    /// Presents the privacy options form, letting the user revisit their consent
    /// choices. Call this from a UI entry point (e.g. a "Privacy Options" button
    /// in Settings) when `isPrivacyOptionsRequired` is `true`.
    ///
    /// - Parameter viewController: The view controller to present from.
    ///   Pass `nil` (default) to let UMP find the top view controller.
    /// - Throws: `AdmobSwiftUIError.consentGatheringFailed` if no form could be presented.
    public func presentPrivacyOptionsForm(from viewController: UIViewController? = nil) async throws {
        defer { syncStatus() }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: viewController)
        } catch {
            AdmobSwiftUI.log("Privacy options form failed: \(error.localizedDescription)", level: .error)
            throw AdmobSwiftUIError.consentGatheringFailed(error)
        }
    }

    /// Requests App Tracking Transparency authorization.
    ///
    /// Google recommends requesting ATT *after* the UMP consent flow completes.
    /// Requires `NSUserTrackingUsageDescription` in the app's Info.plist.
    ///
    /// - Returns: The resulting authorization status.
    @discardableResult
    public func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        let status = await ATTrackingManager.requestTrackingAuthorization()
        AdmobSwiftUI.log("ATT authorization status: \(status.rawValue)", level: .info)
        return status
    }

    /// Clears all consent state from persistent storage. Intended for debugging
    /// and testing only — never call this in production flows.
    public func reset() {
        ConsentInformation.shared.reset()
        syncStatus()
    }

    private func syncStatus() {
        consentStatus = ConsentStatus(ConsentInformation.shared.consentStatus)
    }
}
