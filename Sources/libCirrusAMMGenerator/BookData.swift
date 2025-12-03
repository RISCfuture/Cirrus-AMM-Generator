import Foundation

/// Stores table of contents information downloaded from the AMM website.
///
/// `BookData` is a `Codable` struct that represents the hierarchical structure
/// of an Aircraft Maintenance Manual, consisting of multiple chapters, each
/// containing multiple sections.
///
/// This data is cached to `book.json` in the working directory to allow
/// resumable processing.
struct BookData: Codable, Sendable {

  /// The book title as extracted from the table of contents page.
  var title: String

  /// The chapters of the book in order.
  var chapters = [ChapterData]()

  /// Loads previously saved book data from disk.
  ///
  /// - Parameter url: The file URL where the book data was saved.
  /// - Returns: The decoded `BookData`, or `nil` if the file doesn't exist.
  /// - Throws: Decoding errors if the file exists but cannot be parsed.
  static func fromSavedData(at url: URL) throws -> Self? {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return nil
    }

    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode(Self.self, from: data)
  }

  /// Saves the book data to disk as JSON.
  ///
  /// - Parameter url: The file URL where the book data should be saved.
  /// - Throws: Encoding or file system errors.
  func save(to url: URL) throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(self)
    try data.write(to: url)
  }
}

/// A chapter within the book, consisting of multiple sections.
///
/// Chapters in an AMM are numbered (e.g., "Chapter 05 - Time Limits/Maintenance Checks")
/// with the exception of "Front Matter" which is assigned chapter number 0.
struct ChapterData: Codable, Equatable, Sendable {

  /// The chapter number.
  ///
  /// Front Matter is assigned the chapter number `0`.
  var number: UInt

  /// The chapter title without the number prefix.
  var title: String

  /// The sections making up this chapter.
  var sections = [SectionData]()

  /// The chapter number formatted as a two-digit string (e.g., "05").
  var numberStr: String { String(format: "%02d", number) }

  /// The chapter title with the number prepended (e.g., "05 Time Limits/Maintenance Checks").
  var fullTitle: String { "\(numberStr) \(title)" }

  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.number == rhs.number && lhs.title == rhs.title
  }
}

/// A section within a chapter, representing a single PDF document.
///
/// Each section corresponds to a downloadable PDF file from the Cirrus website.
struct SectionData: Codable, Equatable, Sendable {

  /// The section number within the chapter, if available.
  var number: UInt?

  /// The section title.
  var title: String

  /// The URL where the section's PDF can be downloaded.
  var url: URL

  /// The section number formatted as a two-digit string, or `nil` if unnumbered.
  var numberStr: String? {
    guard let number else { return nil }
    return String(format: "%02d", number)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.number == rhs.number && lhs.title == rhs.title
  }
}
