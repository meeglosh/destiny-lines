import Foundation

/// Local cache of readings so History works offline and immediately after a reading.
/// JSON file in Application Support; the server copy in Postgres is the source of truth.
/// Never stores images or image URLs (§6.1).
@Observable
final class ReadingStore {
    private(set) var readings: [Reading] = []

    private let fileURL: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = support.appendingPathComponent("DestinyLines", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("readings.json")
        load()
    }

    func add(_ reading: Reading) {
        readings.insert(reading, at: 0)
        save()
    }

    /// Replace the cache with the server's list (e.g. after fetchReadings()).
    func replaceAll(_ serverReadings: [Reading]) {
        readings = serverReadings.sorted { $0.createdAt > $1.createdAt }
        save()
    }

    func removeAll() {
        readings = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        readings = (try? decoder.decode([Reading].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(readings) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
