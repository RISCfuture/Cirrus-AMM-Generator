import Foundation
import libCommon

/// Extracts metadata from PDF files using the `pdfinfo` utility.
///
/// `PDFInfo` wraps the Poppler `pdfinfo` command-line tool to extract
/// information about PDF files, such as the page count.
final class PDFInfo: Sendable {

  /// The file URL of the PDF to inspect.
  let url: URL

  /// Creates a new PDF info extractor for the specified file.
  ///
  /// - Parameter url: The local file URL of the PDF to inspect.
  init(url: URL) {
    self.url = url
  }

  /// Returns the number of pages in the PDF.
  ///
  /// This method invokes the `pdfinfo` command and parses its output
  /// to extract the page count.
  ///
  /// - Returns: The number of pages in the PDF.
  /// - Throws: `CirrusAMMGeneratorError.couldntParsePDF` if the PDF
  ///   cannot be read or the page count cannot be determined.
  func pages() async throws -> UInt {
    try await withCheckedThrowingContinuation { continuation in
      do {
        let (process, pipe) = process()
        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit && process.terminationStatus == 0 else {
          continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
          return
        }

        guard let output = try pipe.fileHandleForReading.readToEnd() else {
          continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
          return
        }

        guard let outputStr = String(data: output, encoding: .ascii) else {
          continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
          return
        }

        var found = false
        outputStr.enumerateLines(invoking: { line, stop in
          let rx = #/^Pages:\s+(\d+)$/#
          guard let match = line.wholeMatch(of: rx) else {
            return
          }

          guard let pages = UInt(match.1) else {
            continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: self.url))
            return
          }

          continuation.resume(returning: pages)
          found = true
          stop = true
        })

        if !found {
          continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
        }
      } catch {
        continuation.resume(throwing: error)
        return
      }
    }
  }

  private func process() -> (Process, Pipe) {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(filePath: "/usr/bin/env", directoryHint: .notDirectory)
    process.arguments = ["pdfinfo", url.path]
    process.standardOutput = pipe
    return (process, pipe)
  }
}
