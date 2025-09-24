import Foundation
import libCommon

class StringFileHandle {
  private let fileHandle: FileHandle

  init(url: URL) throws {
    if !FileManager.default.fileExists(atPath: url.path) {
      FileManager.default.createFile(atPath: url.path, contents: nil)
    }
    self.fileHandle = try .init(forWritingTo: url)
  }

  func write(_ string: String) throws {
    guard let data = string.data(using: .utf8) else {
      throw CirrusAMMGeneratorError.badEncoding
    }
    try fileHandle.write(contentsOf: data)
  }

  func close() throws {
    try fileHandle.close()
  }
}
