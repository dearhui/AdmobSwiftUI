import XCTest
@testable import AdmobSwiftUI

@MainActor
final class AdCacheTests: XCTestCase {

    private let baseDate = Date(timeIntervalSince1970: 1_000_000)

    func testStoreAndRetrieve() throws {
        let cache = AdCache<String>(maxSize: 3)
        XCTAssertNil(cache.value(for: "a"))

        cache.store("ad-a", for: "a", at: baseDate)

        XCTAssertEqual(cache.value(for: "a"), "ad-a")
        XCTAssertEqual(cache.lastRequestTime(for: "a"), baseDate)
        XCTAssertEqual(cache.count, 1)
    }

    func testMaxSizeEvictsOldestEntry() throws {
        let cache = AdCache<String>(maxSize: 3)
        cache.store("ad-a", for: "a", at: baseDate)
        cache.store("ad-b", for: "b", at: baseDate.addingTimeInterval(10))
        cache.store("ad-c", for: "c", at: baseDate.addingTimeInterval(20))

        cache.store("ad-d", for: "d", at: baseDate.addingTimeInterval(30))

        XCTAssertEqual(cache.count, 3)
        XCTAssertNil(cache.value(for: "a"), "Oldest entry must be evicted")
        XCTAssertNil(cache.lastRequestTime(for: "a"))
        XCTAssertEqual(cache.value(for: "d"), "ad-d")
    }

    func testRestoringExistingKeyDoesNotEvict() throws {
        let cache = AdCache<String>(maxSize: 2)
        cache.store("ad-a", for: "a", at: baseDate)
        cache.store("ad-b", for: "b", at: baseDate.addingTimeInterval(10))

        // Refreshing "a" replaces in place; "b" must survive.
        cache.store("ad-a2", for: "a", at: baseDate.addingTimeInterval(20))

        XCTAssertEqual(cache.count, 2)
        XCTAssertEqual(cache.value(for: "a"), "ad-a2")
        XCTAssertEqual(cache.value(for: "b"), "ad-b")
    }

    func testHasFreshValueWithinInterval() throws {
        let cache = AdCache<String>(maxSize: 3)
        cache.store("ad-a", for: "a", at: baseDate)

        XCTAssertTrue(cache.hasFreshValue(for: "a", within: 60, now: baseDate.addingTimeInterval(59)))
        XCTAssertFalse(
            cache.hasFreshValue(for: "a", within: 60, now: baseDate.addingTimeInterval(60)),
            "Value is stale once the full interval has elapsed"
        )
    }

    func testHasFreshValueRequiresAStoredValue() throws {
        let cache = AdCache<String>(maxSize: 3)

        XCTAssertFalse(cache.hasFreshValue(for: "a", within: 60, now: baseDate))

        // A request that never completed leaves a timestamp but no value:
        // freshness must be false so the next load() retries.
        cache.markRequested("a", at: baseDate)
        XCTAssertFalse(cache.hasFreshValue(for: "a", within: 60, now: baseDate.addingTimeInterval(1)))
        XCTAssertEqual(cache.lastRequestTime(for: "a"), baseDate)
    }

    func testMarkRequestedRefreshesThrottleWindow() throws {
        let cache = AdCache<String>(maxSize: 3)
        cache.store("ad-a", for: "a", at: baseDate)

        // A later (failed or in-flight) request moves the throttle window forward.
        cache.markRequested("a", at: baseDate.addingTimeInterval(100))

        XCTAssertTrue(cache.hasFreshValue(for: "a", within: 60, now: baseDate.addingTimeInterval(120)))
    }

    func testMaxSizeIsClampedToAtLeastOne() throws {
        let cache = AdCache<String>(maxSize: 0)
        cache.store("ad-a", for: "a", at: baseDate)

        XCTAssertEqual(cache.maxSize, 1)
        XCTAssertEqual(cache.count, 1)

        cache.store("ad-b", for: "b", at: baseDate.addingTimeInterval(10))
        XCTAssertEqual(cache.count, 1)
        XCTAssertEqual(cache.value(for: "b"), "ad-b")
    }
}
