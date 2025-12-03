import Foundation
import libCommon

/// Combines PostScript files into a single PDF using GhostScript.
///
/// `PSToPDFConverter` wraps the GhostScript `gs` command-line tool to merge
/// multiple PostScript files into a single PDF with table of contents bookmarks.
enum PSToPDFConverter {

  /// Combines all PostScript files from a book into a single PDF.
  ///
  /// This method uses GhostScript to merge all the converted PostScript files
  /// and apply the pdfmarks file containing TOC bookmark metadata.
  ///
  /// - Parameters:
  ///   - book: The ``Book`` containing the PostScript files to combine.
  ///   - marksURL: The file URL of the pdfmarks file with TOC metadata.
  ///   - output: The file URL where the final PDF should be saved.
  /// - Throws: `CirrusAMMGeneratorError.couldntConvertPStoPDF` if GhostScript fails.
  static func convert(book: Book, marksURL: URL, output: URL) async throws {
    let process = await self.process(book: book, marksURL: marksURL, output: output)
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
      throw CirrusAMMGeneratorError.couldntConvertPStoPDF
    }
  }

  private static func process(book: Book, marksURL: URL, output: URL) async -> Process {
    let process = Process()
    process.executableURL = URL(filePath: "/usr/bin/env", directoryHint: .notDirectory)
    process.arguments = [
      "gs", "-dBATCH", "-sDEVICE=pdfwrite",
      "-o", output.path
    ]
    await process.arguments!.append(contentsOf: book.psPaths.map(\.path))
    process.arguments!.append(marksURL.path)
    return process
  }
}
