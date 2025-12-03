import ArgumentParser
import Foundation
import Logging
import libCirrusAMMGenerator
import libCommon

/// The command-line interface for generating combined Aircraft Maintenance Manual PDFs.
///
/// This tool downloads AMM, IPC, or WM content from the Cirrus Service Centers website
/// and combines them into a single PDF with a properly formatted table of contents.
///
/// The tool performs the following steps idempotently:
/// 1. Downloads the list of URLs from the table of contents page
/// 2. Downloads each PDF section
/// 3. Converts PDFs to PostScript (removing existing metadata)
/// 4. Generates table-of-contents bookmark metadata
/// 5. Merges all content into the final PDF
///
/// ## Example Usage
///
/// ```bash
/// cirrus-amm-generator http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22/html/ammtoc.html
/// ```
@main
struct CirrusAMMGenerator: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract:
      "Generates a combined PDF of all the Aircraft Maintenance Manuals (AMMs), Illustrated Parts Catalogs (IPCs), and Wiring Manuals (WMs) on the Cirrus Service Centers website.",
    usage: """
      This tool performs the following steps idempotently:

      1. Downloads the list of URLs from a maintenance manual on the
      [Cirrus Service Centers web site](http://servicecenters.cirrusdesign.com/)
      2. Downloads each PDF
      3. Converts each PDF to PostScript (thus removing PDF metadata)
      4. Generates table-of-contents bookmark metadata
      5. Merges the PDFs, in the process applying the new TOC metadata

      The results of each step are saved to the working directory. If the tool fails
      on any one step, it can be re-run without performing already-completed work
      again.
      """
  )

  /// The URL for the AMM/IPC/WM table of contents frame.
  ///
  /// This must be the URL to the specific table of contents frame, not the main AMM page.
  /// See <doc:Usage> for a list of known URLs.
  @Argument(
    help: "The URL for the AMM/IPC/WM table of contents frame",
    transform: { .init(string: $0)! }
  )
  var url: URL

  /// The working directory for temporary files.
  ///
  /// Downloaded PDFs, converted PostScript files, and the final output are stored here.
  /// If the process is interrupted, it can be resumed from this directory.
  @Option(
    name: .shortAndLong,
    help: "The working directory for temporary files (resumable)",
    completion: .directory,
    transform: { .init(filePath: $0, directoryHint: .isDirectory) }
  )
  var work = URL.currentDirectory().appending(path: "work")

  /// The name of the output PDF file.
  ///
  /// The file will be created in the working directory.
  @Option(
    name: .shortAndLong,
    help: "The name of the output PDF file (stored in working directory)"
  )
  var filename = "AMM.pdf"

  /// Enable verbose logging output.
  ///
  /// When enabled, the tool logs progress information for each step.
  @Flag(
    name: .shortAndLong,
    help: "Include extra information in the output."
  )
  var verbose = false

  /// Executes the PDF generation pipeline.
  ///
  /// This method orchestrates the entire process by calling the `Book` actor's
  /// methods in sequence: downloading PDFs, converting to PostScript, and combining
  /// into the final output.
  mutating func run() async throws {
    var logger = Logger(label: "codes.tim.R9ToGarminConverter")
    logger.logLevel = verbose ? .info : .warning

    try FileManager.default.createDirectoryUnlessExists(at: work)

    Task { @MainActor in logger.info("Downloading TOC…") }
    let book = try await Book(tocURL: url, workingDirectory: work, filename: filename)
    await book.setLogger(logger)

    Task { @MainActor in logger.info("Downloading PDFs…") }
    try await book.downloadPDFs()

    Task { @MainActor in logger.info("Converting PDFs to PostScript files…") }
    try await book.convertToPS()

    Task { @MainActor in logger.info("Combining PostScript files to final PDF…") }
    try await book.generatePDFMarks()
    try await book.combinePDFs()

    let path = await book.outputURL.path
    Task { @MainActor in print("Finished book is at \(path)") }
  }
}
