import Foundation
import ArgumentParser
import Logging
import libCommon
import libCirrusAMMGenerator

// http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/amm/SF50/html/ammtoc.html

@available(macOS 13.0, *)
@main
struct CirrusAMMGenerator: AsyncParsableCommand {
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
       
        logger.info("Downloading TOC…")
        let book = try await Book(tocURL: url, workingDirectory: work, filename: filename)
        book.logger = logger
        
        logger.info("Downloading PDFs…")
        try await book.downloadPDFs()
        
        logger.info("Converting PDFs to PostScript files…")
        try await book.convertToPS()
        
        logger.info("Combining PostScript files to final PDF…")
        try await book.generatePDFMarks()
        try await book.combinePDFs()
        
        print("Finished book is at \(book.outputURL.path)")
    }
}
