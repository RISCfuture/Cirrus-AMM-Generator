import Foundation

extension FileManager {
    public func createDirectoryUnlessExists(at url: URL) throws {
        var isDirectory: ObjCBool = false
        if fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                fatalError("File exists at \(url.path)")
            }
            else { return }
        }
        
        try createDirectory(at: url, withIntermediateDirectories: true)
    }
}
