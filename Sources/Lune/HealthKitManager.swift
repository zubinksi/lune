import HealthKit
import SwiftUI

// Reads menstrual cycle data from HealthKit and derives:
//   • currentDay  — 1-indexed day within the active cycle
//   • cycleLength — averaged over up to 6 recent cycles (default 28 if insufficient data)
@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private let flowType = HKCategoryType.categoryType(forIdentifier: .menstrualFlow)!

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization
    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: [flowType])
    }

    // MARK: - Fetch cycle state
    func fetchCycleData() async -> (currentDay: Int, cycleLength: Int) {
        guard isAvailable else { return (19, 28) }

        let samples = await queryFlowSamples(limit: 200)
        guard !samples.isEmpty else { return (1, 28) }

        let cycleStarts = findCycleStarts(from: samples)
        guard let latestStart = cycleStarts.first else { return (1, 28) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysSince = calendar.dateComponents([.day], from: latestStart, to: today).day ?? 0
        let currentDay = max(1, daysSince + 1)

        // Average recent cycle lengths
        var cycleLength = 28
        if cycleStarts.count >= 2 {
            var lengths: [Int] = []
            for i in 0 ..< min(cycleStarts.count - 1, 6) {
                let len = calendar.dateComponents([.day],
                    from: cycleStarts[i + 1],   // earlier start
                    to:   cycleStarts[i]          // later start
                ).day ?? 28
                if (21 ... 40).contains(len) { lengths.append(len) }
            }
            if !lengths.isEmpty {
                cycleLength = lengths.reduce(0, +) / lengths.count
            }
        }

        return (min(currentDay, cycleLength), cycleLength)
    }

    // MARK: - Private helpers

    private func queryFlowSamples(limit: Int) async -> [HKCategorySample] {
        await withCheckedContinuation { cont in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: flowType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sort]
            ) { _, results, _ in
                cont.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }

    // Groups samples into per-day buckets then finds the first day of each
    // period (defined as a cluster of flow days separated from the previous
    // cluster by at least a 5-day gap).
    private func findCycleStarts(from samples: [HKCategorySample]) -> [Date] {
        let calendar = Calendar.current

        // Unique days that had any flow, sorted descending (newest first)
        let flowDays = Array(
            Set(samples.map { calendar.startOfDay(for: $0.startDate) })
        ).sorted(by: >)

        guard !flowDays.isEmpty else { return [] }

        var cycleStarts: [Date] = []
        var clusterEnd: Date = flowDays[0]   // end of current cluster (newest day)
        var clusterStart: Date = flowDays[0] // walking backwards through the cluster

        for i in 1 ..< flowDays.count {
            let prev = flowDays[i - 1]
            let curr = flowDays[i]
            let gap = calendar.dateComponents([.day], from: curr, to: prev).day ?? 0

            if gap <= 2 {
                // Same cluster — extend start backwards
                clusterStart = curr
            } else {
                // Gap ≥ 3 days: the cluster just ended; record its start
                cycleStarts.append(clusterStart)
                clusterStart = curr
                clusterEnd = curr
            }
        }
        // Record the oldest cluster
        cycleStarts.append(clusterStart)

        // cycleStarts is already newest-first because we walked descending flow days
        return cycleStarts
    }
}
