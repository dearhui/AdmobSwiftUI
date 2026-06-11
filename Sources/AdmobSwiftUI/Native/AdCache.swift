//
//  AdCache.swift
//  AdmobSwiftUI
//

import Foundation

/// In-memory cache keyed by ad unit ID, with a size cap and request-time
/// tracking for throttling. Backs `NativeAdViewModel`'s shared native ad cache;
/// generic over `Value` so tests don't need real SDK ad objects.
@MainActor
final class AdCache<Value> {

    /// Maximum number of values kept; storing beyond this evicts the entry
    /// with the oldest request time.
    let maxSize: Int

    private var values: [String: Value] = [:]
    private var lastRequestTimes: [String: Date] = [:]

    init(maxSize: Int) {
        self.maxSize = max(1, maxSize)
    }

    var count: Int { values.count }

    func value(for key: String) -> Value? {
        values[key]
    }

    func lastRequestTime(for key: String) -> Date? {
        lastRequestTimes[key]
    }

    /// Records that a request for `key` started, so throttling also covers
    /// in-flight and failed requests, not just successful ones.
    func markRequested(_ key: String, at date: Date = Date()) {
        lastRequestTimes[key] = date
    }

    /// `true` while a cached value exists and the last request for `key`
    /// is younger than `interval` — i.e. a new request should be skipped.
    func hasFreshValue(for key: String, within interval: TimeInterval, now: Date = Date()) -> Bool {
        guard values[key] != nil, let lastRequest = lastRequestTimes[key] else { return false }
        return now.timeIntervalSince(lastRequest) < interval
    }

    func store(_ value: Value, for key: String, at date: Date = Date()) {
        evictOldestIfNeeded(insertingKey: key)
        values[key] = value
        lastRequestTimes[key] = date
    }

    private func evictOldestIfNeeded(insertingKey key: String) {
        guard values[key] == nil, values.count >= maxSize else { return }
        let oldestKey = values.keys.min {
            (lastRequestTimes[$0] ?? .distantPast) < (lastRequestTimes[$1] ?? .distantPast)
        }
        if let oldestKey {
            values.removeValue(forKey: oldestKey)
            lastRequestTimes.removeValue(forKey: oldestKey)
        }
    }
}
