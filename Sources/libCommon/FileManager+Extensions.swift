import Foundation

extension FileManager {

  /// Creates a directory at the specified URL if it does not already exist.
  ///
  /// If a directory already exists at the given path, this method returns without taking any action.
  /// If a file (not a directory) exists at the path, the method will call `fatalError`.
  ///
  /// - Parameter url: The file URL where the directory should be created.
  /// - Throws: An error if the directory cannot be created.
  package func createDirectoryUnlessExists(at url: URL) throws {
    var isDirectory: ObjCBool = false
    if fileExists(atPath: url.path, isDirectory: &isDirectory) {
      if !isDirectory.boolValue {
        fatalError("File exists at \(url.path)")
      } else {
        return
      }
    }

    try createDirectory(at: url, withIntermediateDirectories: true)
  }
}
