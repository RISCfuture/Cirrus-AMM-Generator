import Foundation
import libCommon

enum PDFDownloader {
  private static var session: URLSession { .init(configuration: .ephemeral) }

  static func download(from source: URL, to destination: URL) async throws {
    let (tempfileURL, response) = try await Self.session.download(from: source)
    guard let response = response as? HTTPURLResponse else {
      throw CirrusAMMGeneratorError.downloadFailed(url: source, response: response)
    }
    guard response.statusCode / 100 == 2 else {
      throw CirrusAMMGeneratorError.downloadFailed(url: source, response: response)
    }

    try FileManager.default.createDirectoryUnlessExists(at: destination.deletingLastPathComponent())
    try FileManager.default.moveItem(at: tempfileURL, to: destination)
  }
}
