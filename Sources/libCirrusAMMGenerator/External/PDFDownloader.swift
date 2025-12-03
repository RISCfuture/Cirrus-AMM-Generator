import Foundation
import libCommon

/// Downloads PDF files from remote URLs.
///
/// This enum provides a static method for downloading PDFs from the Cirrus
/// Service Centers website and saving them to the local file system.
enum PDFDownloader {
  private static var session: URLSession { .init(configuration: .ephemeral) }

  /// Downloads a PDF from a remote URL to a local file.
  ///
  /// Creates intermediate directories as needed and moves the downloaded file
  /// to the destination path.
  ///
  /// - Parameters:
  ///   - source: The remote URL to download from.
  ///   - destination: The local file URL where the PDF should be saved.
  /// - Throws: `CirrusAMMGeneratorError.downloadFailed` if the
  ///   download fails or returns a non-2xx status code.
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
