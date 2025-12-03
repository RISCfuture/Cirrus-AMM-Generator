import Foundation
import libCommon

/// Converts PDF files to PostScript format using the `pdftops` utility.
///
/// `PDFToPSConverter` wraps the Poppler `pdftops` command-line tool to convert
/// PDF files to PostScript. This conversion strips existing PDF metadata,
/// which is necessary before recombining files with new TOC metadata.
enum PDFToPSConverter {

  /// Converts a PDF file to PostScript format.
  ///
  /// - Parameters:
  ///   - input: The local file URL of the PDF to convert.
  ///   - output: The local file URL where the PostScript file should be saved.
  /// - Throws: `CirrusAMMGeneratorError.couldntConvertPDFToPS` if the
  ///   conversion fails.
  static func convert(from input: URL, to output: URL) async throws {
    // swiftlint:disable:next return_value_from_void_function
    return try await withCheckedThrowingContinuation { continuation in
      let process = process(input: input, output: output)
      do {
        try process.run()
      } catch {
        continuation.resume(throwing: error)
        return
      }
      process.waitUntilExit()

      guard process.terminationStatus == 0 else {
        continuation.resume(throwing: CirrusAMMGeneratorError.couldntConvertPDFToPS(url: input))
        return
      }

      continuation.resume(returning: ())
    }
  }

  private static func process(input: URL, output: URL) -> Process {
    let process = Process()
    process.executableURL = URL(filePath: "/usr/bin/env", directoryHint: .notDirectory)
    process.arguments = ["pdftops", input.path, output.path]
    return process
  }
}
