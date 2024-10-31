import Foundation
import Logging
import libCommon

/**
 The primary class for generaring AMM PDFs.
 
 To use, initialize an instance using
 ``init(tocURL:workingDirectory:filename:)``, and then call the following
 methods in order:
 
 * ``downloadPDFs()``
 * ``generatePDFMarks()``
 * ``convertToPS()``
 * ``combinePDFs()``
 
 In-progress files will be saved in ``workingDirectory``, so if the process is
 aborted, it can be resumed (with the same ``workingDirectory``) where it left
 off.
 */

public class Book {
    var data: BookData
    
    /// The URL for the Table of Contents HTML page.
    public let tocURL: URL
    
    /// A logger to record progress.
    public var logger: Logger? = nil
    
    /// The path where working files are stored, as well the output file.
    public let workingDirectory: URL
    
    /// The filename for the generated PDF.
    public let filename: String
    
    /// The path where the TOC data is cached after being downloaded.
    let bookInfoURL: URL
    
    /// The path where PDFs are downloaded.
    lazy var pdfsURL = workingDirectory.appending(path: "pdfs")
    
    /// The path where converted PostScript files are stored.
    lazy var psURL = workingDirectory.appending(path: "ps")
    
    /// The path where table of contents metadata for the final PDF is saved.
    lazy var pdfMarksURL = workingDirectory.appending(path: "pdfmarks")
    
    /// The path where the final PDF is generated.
    lazy public var outputURL = workingDirectory.appending(path: filename)
    
    lazy var chapters = data.chapters.map { Chapter(book: self, data: $0) }
    
    /// An ordered array of all the PDFs to merge.
    lazy var pdfPaths: Array<URL> = chapters.reduce(into: []) { paths, chapter in
        for section in chapter.sections {
            guard section.isDownloaded else { fatalError("PDFs not yet downloaded") }
            paths.append(section.pdfURL)
        }
    }
    
    /// An ordered array of all the converted PostScript files to merge.
    lazy var psPaths: Array<URL> = chapters.reduce(into: []) { paths, chapter in
        for section in chapter.sections {
            guard section.isDownloaded else { fatalError("PDFs not yet downloaded") }
            paths.append(section.psURL)
        }
    }
    
    /**
     Creates a new PDF generator. This initializer attempts to read
     already-downloaded table of contents data from `workingDirectory`;
     otherwise, it downloads TOC data from `tocURL` and saves it to
     `workingDirectory`.
     
     - Parameter tocURL: The URL to the Table of Contents frame for the manual's
                         HTML page.
     - Parameter workingDirectory: The location where in-progress files are
                                   stored, as well as the output file.
     - Parameter filename: The name of the generated PDF file.
     */
    public init(tocURL: URL, workingDirectory: URL, filename: String) async throws {
        self.tocURL = tocURL
        self.workingDirectory = workingDirectory
        bookInfoURL = workingDirectory.appending(path: "book.json")
        self.filename = filename
        
        if let data = try BookData.fromSavedData(at: bookInfoURL) {
            self.data = data
        } else {
            self.data = try await TOCReader(url: tocURL).data()
            try self.saveBookData()
        }
    }
    
    /// Downloads all PDF chapter files into ``workingDirectory``.
    public func downloadPDFs() async throws {
        try await eachSection() { section in
            guard !section.isDownloaded else { return false }
            
            self.logger?.info("-- Downloading \(section.data.title)")
            try FileManager.default.createDirectoryUnlessExists(at: section.pdfURL.deletingLastPathComponent())
            do {
                try await PDFDownloader.download(from: section.data.url, to: section.pdfURL)
            } catch {
                if section.data.title == "Log of Temporary Revisions" || section.data.title == "33-40-07 Step Lights" { return true }
                else { throw error }
            }
            return false
        }
    }
    
    /// Generates the table of contents data for the output PDF.
    public func generatePDFMarks() async throws {
        try FileManager.default.createDirectoryUnlessExists(at: pdfMarksURL.deletingLastPathComponent())
        if FileManager.default.fileExists(atPath: pdfMarksURL.path) { return }
        
        let handle = try StringFileHandle(url: pdfMarksURL)
        
        do {
            let pdfMarks = """
        [ /Title (#{book.title})
          /Author (Cirrus Design Inc.)\n
        """
            try handle.write(pdfMarks)
            
            for chapter in chapters {
                let sections = chapter.sections.count
                let title = chapter.data.fullTitle
                let page = try await chapter.firstPage()
                try handle.write("[/Count -\(sections) /Title (\(title)) /Page \(page) /OUT pdfmark\n")
                
                for section in chapter.sections {
                    let title = section.fullTitle
                    let page = try await section.firstPage()
                    try handle.write("[/Title (\(title)) /Page \(page) /OUT pdfmark\n")
                }
            }
        } catch (let error as CirrusAMMGeneratorError) {
            switch error {
                case .badEncoding: throw CirrusAMMGeneratorError.badTOC
                default: throw error
            }
        }
    }
    
    /// Converts all downloaded PDFs to PostScript files. This is necessary to
    /// strip existing TOC metadata.
    public func convertToPS() async throws {
        try await eachSection() { section in
            guard !section.isConverted else { return false }
            
            self.logger?.info("-- Converting \(section.data.title)")
            try FileManager.default.createDirectoryUnlessExists(at: section.psURL.deletingLastPathComponent())
            try await PDFToPSConverter.convert(from: section.pdfURL, to: section.psURL)
            
            return false
        }
    }
    
    /// Combined converted PDF files into the output file, stored at
    /// ``outputURL``.
    public func combinePDFs() async throws {
        try FileManager.default.createDirectoryUnlessExists(at: outputURL.deletingLastPathComponent())
        try await PSToPDFConverter.convert(book: self, marksURL: pdfMarksURL, output: outputURL)
    }
    
    private func eachSection(_ handler: @escaping (Section) async throws -> Bool) async throws {
        try await withThrowingTaskGroup(of: (Int, URL)?.self) { group in
            for (chapterIndex, chapter) in self.chapters.enumerated() {
                for section in chapter.sections {
                    group.addTask {
                        let shouldDelete = try await handler(section)
                        return shouldDelete ? (chapterIndex, section.data.url) : nil
                    }
                }
            }
            
            for try await toDelete in group {
                guard let toDelete = toDelete else { continue }
                chapters[toDelete.0].sections.removeAll(where: { $0.data.url == toDelete.1 })
            }
            try self.saveBookData()
        }
    }
    
    private func saveBookData() throws {
        try self.data.save(to: bookInfoURL)
    }
}

class Chapter {
    weak var book: Book?
    var data: ChapterData
    
    lazy var sections = data.sections.map { Section(chapter: self, data: $0) }
    private var _pages: UInt? = nil
    private var _firstPage: UInt? = nil
    
    private var previous: Chapter? {
        guard let book = book else { fatalError("No Book for Chapter") }
        guard let index = book.data.chapters.firstIndex(where: { data == $0 }) else {
            fatalError("Can’t find Chapter in Book")
        }
        guard index > 0 else { return nil }
        
        return book.chapters[index - 1]
    }
    
    init(book: Book, data: ChapterData) {
        self.book = book
        self.data = data
    }

    /// The number of pages in this chapter.

    func pages() async throws -> UInt {
        if let _pages = _pages { return _pages }
        
        var pages: UInt = 0
        for section in sections {
            pages += try await section.pages()
        }
        _pages = pages
        return pages
    }
    
    /// The page that the chapter begins at (1-indexed).
    func firstPage() async throws -> UInt {
        if let _firstPage = _firstPage { return _firstPage }
        
        guard let previous = previous else { return 1 }
        _firstPage = try await previous.firstPage() + previous.pages()
        return _firstPage!
    }
}

class Section {
    private weak var chapter: Chapter?
    var data: SectionData
    
    lazy private var book = chapter?.book
    private var _pages: UInt? = nil
    private var _firstPage: UInt? = nil
    
    var fullTitle: String {
        guard let chapter = chapter else { fatalError("No Chapter for Section") }
        if let numberStr = data.numberStr {
            return "\(chapter.data.numberStr)-\(numberStr) \(data.title)"
        } else {
            return data.title
        }
    }
    
    /// The path where the PDF is (or will be) downloaded to.
    var pdfURL: URL {
        guard let book = book else { fatalError("No Book for Section") }
        return book.pdfsURL.appending(path: basename(extension: "pdf"))
    }
    
    /// The path where the converted PostScript file is (or will be) saved.
    var psURL: URL {
        guard let book = book else { fatalError("No Book for Section") }
        return book.psURL.appending(path: basename(extension: "ps"))
    }
    
    /// Whether or not the PDF has been downloaded.
    var isDownloaded: Bool {
        FileManager.default.fileExists(atPath: pdfURL.path)
    }
    
    /// Whether or not the PDF has been converted to a PostScript file.
    var isConverted: Bool {
        FileManager.default.fileExists(atPath: psURL.path)
    }
    
    private var pdfInfo: PDFInfo { .init(url: pdfURL) }
    
    private var previous: Section? {
        guard let chapter = chapter else { fatalError("No Chapter for Section") }
        guard let index = chapter.data.sections.firstIndex(where: { data == $0 }) else {
            fatalError("Can’t find Section in Chapter")
        }
        guard index > 0 else { return nil }
        
        return chapter.sections[index - 1]
    }
    
    init(chapter: Chapter, data: SectionData) {
        self.chapter = chapter
        self.data = data
    }
    
    func firstPage() async throws -> UInt {
        if let _firstPage = _firstPage { return _firstPage }
        
        guard let chapter = chapter else {
            fatalError("No Chapter for Section")
        }
        guard let previous = previous else { return try await chapter.firstPage() }
        
        _firstPage = try await previous.firstPage() + previous.pages()
        return _firstPage!
    }
    
    func pages() async throws -> UInt {
        if let _pages = _pages { return _pages }
        _pages = try await pdfInfo.pages()
        return _pages!
    }
    
    private func basename(`extension`: String) -> String {
        guard let chapter = chapter else { fatalError("No Chapter for Section") }
        let name = fullTitle.replacingOccurrences(of: "/", with: "-")
        
        return [
            chapter.data.fullTitle.replacingOccurrences(of: "/", with: "-"),
            "\(name).\(`extension`)"
        ].joined(separator: "/")
    }
}
