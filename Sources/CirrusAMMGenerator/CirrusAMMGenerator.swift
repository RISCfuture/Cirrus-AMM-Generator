import Foundation
import ArgumentParser
import Logging
import libCommon
import libCirrusAMMGenerator

// http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/amm/SF50/html/ammtoc.html

@main
struct CirrusAMMGenerator: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Generates a combined PDF of all the Aircraft Maintenance Manuals (AMMs), Illustrated Parts Catalogs (IPCs), and Wiring Manuals (WMs) on the Cirrus Service Centers website.",
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
            """)
    
    @Argument(help: "The URL for the AMM/IPC/WM table of contents frame",
              transform: { URL(string: $0)! })
    var url: URL
    
    @Option(name: .shortAndLong,
            help: "The working directory for temporary files (resumable)",
            transform: { URL(filePath: $0) })
//    var work = URL(filePath: NSTemporaryDirectory())
    var work = Process().currentDirectoryURL!.appending(path: "work")
    
    @Option(name: .shortAndLong,
            help: "The name of the output PDF file (stored in working directory)")
    var filename = "AMM.pdf"
    
    @Flag(name: .shortAndLong,
          help: "Include extra information in the output.")
    var verbose = false
    
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
