import Foundation
import libCommon

/// A file handle wrapper for writing UTF-8 encoded strings.
///
/// `StringFileHandle` provides a convenient way to write string content to files,
/// automatically handling UTF-8 encoding.
class StringFileHandle {
  private let fileHandle: FileHandle

  /// Creates a new string file handle for writing to the specified URL.
  ///
  /// If the file does not exist, it will be created. The file handle is opened
  /// for writing.
  ///
  /// - Parameter url: The file URL to write to.
  /// - Throws: An error if the file handle cannot be opened for writing.
  init(url: URL) throws {
    if !FileManager.default.fileExists(atPath: url.path) {
      FileManager.default.createFile(atPath: url.path, contents: nil)
    }
    self.fileHandle = try .init(forWritingTo: url)
  }

  /// Writes a string to the file, encoding it as UTF-8.
  ///
  /// - Parameter string: The string to write.
  /// - Throws: `CirrusAMMGeneratorError.badEncoding` if the string cannot
  ///   be encoded as UTF-8.
  func write(_ string: String) throws {
    guard let data = string.data(using: .utf8) else {
      throw CirrusAMMGeneratorError.badEncoding
    }
    try fileHandle.write(contentsOf: data)
  }

  /// Closes the file handle.
  ///
  /// - Throws: An error if the file handle cannot be closed.
  func close() throws {
    try fileHandle.close()
  }
}
