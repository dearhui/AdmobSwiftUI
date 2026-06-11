import XCTest
import UIKit
@testable import AdmobSwiftUI

// MARK: - Mock

@MainActor
private final class MockConsentService: ConsentService {
    var consentStatus: ConsentStatus = .unknown
    var canRequestAds = false
    var isPrivacyOptionsRequired = false

    /// Status the mock transitions to after a successful info update / form presentation,
    /// simulating UMP's state machine.
    var statusAfterInfoUpdate: ConsentStatus?
    var statusAfterFormPresentation: ConsentStatus?

    var infoUpdateError: (any Error)?
    var formError: (any Error)?
    var privacyOptionsError: (any Error)?

    private(set) var infoUpdateCalls: [(tagForUnderAgeOfConsent: Bool, debugSettings: ConsentDebugSettings?)] = []
    private(set) var formPresentationCount = 0
    private(set) var privacyOptionsCount = 0
    private(set) var resetCount = 0

    func requestConsentInfoUpdate(
        tagForUnderAgeOfConsent: Bool,
        debugSettings: ConsentDebugSettings?
    ) async throws {
        infoUpdateCalls.append((tagForUnderAgeOfConsent, debugSettings))
        if let infoUpdateError { throw infoUpdateError }
        if let statusAfterInfoUpdate { consentStatus = statusAfterInfoUpdate }
    }

    func loadAndPresentConsentFormIfRequired(from viewController: UIViewController?) async throws {
        formPresentationCount += 1
        if let formError { throw formError }
        if let statusAfterFormPresentation {
            consentStatus = statusAfterFormPresentation
            canRequestAds = true
        }
    }

    func presentPrivacyOptionsForm(from viewController: UIViewController?) async throws {
        privacyOptionsCount += 1
        if let privacyOptionsError { throw privacyOptionsError }
    }

    func reset() {
        resetCount += 1
        consentStatus = .unknown
        canRequestAds = false
    }
}

// MARK: - Tests

@MainActor
final class ConsentManagerTests: XCTestCase {

    private var service: MockConsentService!
    private var manager: ConsentManager!

    override func setUp() async throws {
        service = MockConsentService()
        manager = ConsentManager(service: service)
    }

    func testInitReadsStatusFromService() throws {
        service.consentStatus = .obtained
        let manager = ConsentManager(service: service)
        XCTAssertEqual(manager.consentStatus, .obtained)
    }

    func testGatherConsentRunsUpdateThenFormAndSyncsStatus() async throws {
        service.statusAfterInfoUpdate = .required
        service.statusAfterFormPresentation = .obtained

        try await manager.gatherConsent()

        XCTAssertEqual(service.infoUpdateCalls.count, 1)
        XCTAssertEqual(service.formPresentationCount, 1)
        XCTAssertEqual(manager.consentStatus, .obtained)
        XCTAssertTrue(manager.canRequestAds)
    }

    func testGatherConsentForwardsParameters() async throws {
        let debugSettings = ConsentDebugSettings(geography: .eea, testDeviceIdentifiers: ["abc"])
        try await manager.gatherConsent(debugSettings: debugSettings, tagForUnderAgeOfConsent: true)

        XCTAssertEqual(service.infoUpdateCalls.count, 1)
        XCTAssertTrue(service.infoUpdateCalls[0].tagForUnderAgeOfConsent)
        XCTAssertEqual(service.infoUpdateCalls[0].debugSettings, debugSettings)
    }

    func testGatherConsentInfoUpdateFailureThrowsAndStillSyncsStatus() async throws {
        service.infoUpdateError = NSError(domain: "ump", code: 1)
        // Simulate UMP having a persisted status even though the update failed.
        service.consentStatus = .obtained

        do {
            try await manager.gatherConsent()
            XCTFail("Expected gatherConsent to throw")
        } catch {
            guard case AdmobSwiftUIError.consentGatheringFailed = error else {
                return XCTFail("Expected consentGatheringFailed, got \(error)")
            }
        }
        XCTAssertEqual(service.formPresentationCount, 0, "Form must not be presented when the info update fails")
        XCTAssertEqual(manager.consentStatus, .obtained, "Status must sync even on failure")
    }

    func testGatherConsentFormFailureThrowsConsentGatheringFailed() async throws {
        service.statusAfterInfoUpdate = .required
        service.formError = NSError(domain: "ump", code: 2)

        do {
            try await manager.gatherConsent()
            XCTFail("Expected gatherConsent to throw")
        } catch {
            guard case AdmobSwiftUIError.consentGatheringFailed = error else {
                return XCTFail("Expected consentGatheringFailed, got \(error)")
            }
        }
        XCTAssertEqual(manager.consentStatus, .required, "Status from the successful info update must be kept")
    }

    func testPresentPrivacyOptionsFormCallsServiceAndSyncs() async throws {
        service.statusAfterInfoUpdate = nil
        service.consentStatus = .obtained

        try await manager.presentPrivacyOptionsForm()

        XCTAssertEqual(service.privacyOptionsCount, 1)
        XCTAssertEqual(manager.consentStatus, .obtained)
    }

    func testPresentPrivacyOptionsFormFailureWrapsError() async throws {
        service.privacyOptionsError = NSError(domain: "ump", code: 3)

        do {
            try await manager.presentPrivacyOptionsForm()
            XCTFail("Expected presentPrivacyOptionsForm to throw")
        } catch {
            guard case AdmobSwiftUIError.consentGatheringFailed = error else {
                return XCTFail("Expected consentGatheringFailed, got \(error)")
            }
        }
    }

    func testResetClearsStatus() async throws {
        service.statusAfterInfoUpdate = .required
        service.statusAfterFormPresentation = .obtained
        try await manager.gatherConsent()
        XCTAssertEqual(manager.consentStatus, .obtained)

        manager.reset()

        XCTAssertEqual(service.resetCount, 1)
        XCTAssertEqual(manager.consentStatus, .unknown)
        XCTAssertFalse(manager.canRequestAds)
    }

    func testPassthroughProperties() throws {
        XCTAssertFalse(manager.canRequestAds)
        XCTAssertFalse(manager.isPrivacyOptionsRequired)

        service.canRequestAds = true
        service.isPrivacyOptionsRequired = true

        XCTAssertTrue(manager.canRequestAds)
        XCTAssertTrue(manager.isPrivacyOptionsRequired)
    }
}
