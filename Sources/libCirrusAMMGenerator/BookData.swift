import Foundation

/**
 Stores table of contents information downloaded from the AMM website,
 consisting of multiple ``Chapter``s.
 */
struct BookData: Codable, Sendable {

    /// The book title.
    var title: String

    /// The chapters of the book.
    var chapters = [ChapterData]()

    static func fromSavedData(at url: URL) throws -> Self? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: data)
    }

    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}

/// A chapter within the book, consisting of multiple ``Section``s.
struct ChapterData: Codable, Equatable, Sendable {

    /// The chapter number. (Front Matter is given the chapter number `0`.)
    var number: UInt

    /// The chapter title.
    var title: String

    /// The sections making up this chapter.
    var sections = [SectionData]()

    var numberStr: String { String(format: "%02d", number) }

    /// The chapter title with the number prepended.
    var fullTitle: String { "\(numberStr) \(title)" }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.number == rhs.number && lhs.title == rhs.title
    }
}

struct SectionData: Codable, Equatable, Sendable {
    var number: UInt?
    var title: String
    var url: URL

    var numberStr: String? {
        guard let number else { return nil }
        return String(format: "%02d", number)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.number == rhs.number && lhs.title == rhs.title
    }
}
