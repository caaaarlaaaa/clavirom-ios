import Foundation

/// Loads the Vallader word list (word\tfrequency) and returns the most likely
/// completions for a prefix. Entries are kept sorted by a lowercased key so a
/// prefix range can be found with a binary search instead of a full scan.
final class SuggestionEngine {

    private struct Entry {
        let word: String   // original casing, as shown/inserted
        let key: String    // lowercased, for matching
        let freq: Int      // 0–255, higher = more common
    }

    private var entries: [Entry] = []

    /// Loads `rm-VA.tsv` from the extension bundle. Cheap enough (~195k lines)
    /// to do synchronously at keyboard launch.
    func load(resource: String = "rm-VA", ext: String = "tsv") {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        var parsed: [Entry] = []
        parsed.reserveCapacity(200_000)
        text.enumerateLines { line, _ in
            guard let tab = line.firstIndex(of: "\t") else { return }
            let word = String(line[..<tab])
            let freq = Int(line[line.index(after: tab)...]) ?? 0
            guard !word.isEmpty else { return }
            parsed.append(Entry(word: word, key: word.lowercased(), freq: freq))
        }
        parsed.sort { $0.key < $1.key }
        entries = parsed
    }

    /// Up to `limit` suggestions for `prefix`, ranked by frequency.
    func suggestions(for prefix: String, limit: Int = 3) -> [String] {
        let key = prefix.lowercased()
        guard !key.isEmpty, !entries.isEmpty else { return [] }

        var lo = 0
        var hi = entries.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if entries[mid].key < key { lo = mid + 1 } else { hi = mid }
        }

        var matches: [Entry] = []
        var i = lo
        while i < entries.count, entries[i].key.hasPrefix(key) {
            // Skip the exact word the user already typed.
            if entries[i].key != key { matches.append(entries[i]) }
            i += 1
            if matches.count > 400 { break } // cap work on very short prefixes
        }
        return matches
            .sorted { $0.freq > $1.freq }
            .prefix(limit)
            .map { $0.word }
    }
}
