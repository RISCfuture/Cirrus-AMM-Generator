import Foundation
import libCommon

enum PSToPDFConverter {
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
