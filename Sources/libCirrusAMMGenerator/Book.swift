import Foundation
import libCommon
import Logging

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

public actor Book {
    var data: BookData

    /// The URL for the Table of Contents HTML page.
    public let tocURL: URL

    /// A logger to record progress.
    public var logger: Logger?

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
    public lazy var outputURL = workingDirectory.appending(path: filename)

    lazy var chapters = data.chapters.map { Chapter(book: self, data: $0) }

    /// An ordered array of all the PDFs to merge.
    var pdfPaths: [URL] {
        get async {
            var pdfPaths = [URL]()
            for chapter in chapters {
                for section in await chapter.sections {
                    guard await section.isDownloaded else { fatalError("PDFs not yet downloaded") }
                    await pdfPaths.append(section.pdfURL)
                }
            }
            return pdfPaths
        }
    }

    /// An ordered array of all the converted PostScript files to merge.
    var psPaths: [URL] {
        get async {
            var psPaths = [URL]()
            for chapter in chapters {
                for section in await chapter.sections {
                    guard await section.isDownloaded else { fatalError("PDFs not yet downloaded") }
                    await psPaths.append(section.psURL)
                }
            }
            return psPaths
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

    /// Sets the logger.
    public func setLogger(_ logger: Logger?) { self.logger = logger }

    /// Downloads all PDF chapter files into ``workingDirectory``.
    public func downloadPDFs() async throws {
        let urlsToRemove = try await withThrowingTaskGroup(of: (Int, URL)?.self) { group in
            for (chapterIndex, chapter) in self.chapters.enumerated() {
                for section in await chapter.sections {
                    guard await !section.isDownloaded else { continue }

                    group.addTask {
                        let title = await section.data.title
                        Task { @MainActor in await self.logger?.info("-- Downloading \(title)") }
                        try await FileManager.default.createDirectoryUnlessExists(at: section.pdfURL.deletingLastPathComponent())
                        do {
                            try await PDFDownloader.download(from: section.data.url, to: section.pdfURL)
                        } catch {
                            if title == "Log of Temporary Revisions" || title == "33-40-07 Step Lights" {
                                return await (chapterIndex, section.data.url)
                            }
                            throw error
                        }
                        return nil
                    }
                }
            }

            var urlsToRemove = [Int: Set<URL>]()
            for try await pair in group {
                guard let (chapterIndex, sectionURL) = pair else { continue }
                urlsToRemove[chapterIndex, default: Set()].insert(sectionURL)
            }
            return urlsToRemove
        }

        for (chapterIndex, urls) in urlsToRemove {
            await chapters[chapterIndex].removeAllSections(matchingURLs: urls)
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
                let sections = await chapter.sections.count
                let title = await chapter.data.fullTitle
                let page = try await chapter.firstPage()
                try handle.write("[/Count -\(sections) /Title (\(title)) /Page \(page) /OUT pdfmark\n")

                for section in await chapter.sections {
                    let title = await section.fullTitle
                    let page = try await section.firstPage()
                    try handle.write("[/Title (\(title)) /Page \(page) /OUT pdfmark\n")
                }
            }
        } catch let error as CirrusAMMGeneratorError {
            switch error {
                case .badEncoding: throw CirrusAMMGeneratorError.badTOC
                default: throw error
            }
        }
    }

    /// Converts all downloaded PDFs to PostScript files. This is necessary to
    /// strip existing TOC metadata.
    public func convertToPS() async throws {
        try await withThrowingDiscardingTaskGroup { group in
            for chapter in self.chapters {
                for section in await chapter.sections {
                    guard await !section.isConverted else { continue }

                    group.addTask {
                        let title = await section.data.title
                        Task { @MainActor in await self.logger?.info("-- Converting \(title)") }
                        try await FileManager.default.createDirectoryUnlessExists(at: section.psURL.deletingLastPathComponent())
                        try await PDFToPSConverter.convert(from: section.pdfURL, to: section.psURL)
                    }
                }
            }
        }
    }

    /// Combined converted PDF files into the output file, stored at
    /// ``outputURL``.
    public func combinePDFs() async throws {
        try FileManager.default.createDirectoryUnlessExists(at: outputURL.deletingLastPathComponent())
        try await PSToPDFConverter.convert(book: self, marksURL: pdfMarksURL, output: outputURL)
    }

    private func saveBookData() throws {
        try self.data.save(to: bookInfoURL)
    }
}

actor Chapter {
    unowned var book: Book
    var data: ChapterData

    lazy var sections = data.sections.map { Section(chapter: self, data: $0) }
    private var _pages: UInt?
    private var _firstPage: UInt?

    private var previous: Chapter? {
        get async {
            guard let index = await book.data.chapters.firstIndex(where: { data == $0 }) else {
                fatalError("Can’t find Chapter in Book")
            }
            guard index > 0 else { return nil }

            return await book.chapters[index - 1]
        }
    }

    init(book: Book, data: ChapterData) {
        self.book = book
        self.data = data
    }

    /// The number of pages in this chapter.

    func pages() async throws -> UInt {
        if let _pages { return _pages }

        var pages: UInt = 0
        for section in sections {
            pages += try await section.pages()
        }
        _pages = pages
        return pages
    }

    /// The page that the chapter begins at (1-indexed).
    func firstPage() async throws -> UInt {
        if let _firstPage { return _firstPage }

        guard let previous = await previous else { return 1 }
        _firstPage = try await previous.firstPage() + previous.pages()
        return _firstPage!
    }

    func removeAllSections(matchingURLs urls: Set<URL>) async {
        var newSections = [Section]()
        for section in sections where await !urls.contains(section.data.url) {
            newSections.append(section)
        }
        sections = newSections
    }
}

actor Section {
    private unowned var chapter: Chapter
    var data: SectionData

    private var book: Book! { get async { await chapter.book } }
    private var _pages: UInt?
    private var _firstPage: UInt?

    var fullTitle: String {
        get async {
            if let numberStr = data.numberStr {
                return await "\(chapter.data.numberStr)-\(numberStr) \(data.title)"
            }
            return data.title
        }
    }

    /// The path where the PDF is (or will be) downloaded to.
    var pdfURL: URL {
        get async {
            return await book.pdfsURL.appending(path: basename(extension: "pdf"))
        }
    }

    /// The path where the converted PostScript file is (or will be) saved.
    var psURL: URL {
        get async {
            return await book.psURL.appending(path: basename(extension: "ps"))
        }
    }

    /// Whether or not the PDF has been downloaded.
    var isDownloaded: Bool {
        get async {
            await FileManager.default.fileExists(atPath: pdfURL.path)
        }
    }

    /// Whether or not the PDF has been converted to a PostScript file.
    var isConverted: Bool {
        get async {
            await FileManager.default.fileExists(atPath: psURL.path)
        }
    }

    private var pdfInfo: PDFInfo {
        get async {
            await .init(url: pdfURL)
        }
    }

    private var previous: Section? {
        get async {
            guard let index = await chapter.data.sections.firstIndex(where: { data == $0 }) else {
                fatalError("Can’t find Section in Chapter")
            }
            guard index > 0 else { return nil }

            return await chapter.sections[index - 1]
        }
    }

    init(chapter: Chapter, data: SectionData) {
        self.chapter = chapter
        self.data = data
    }

    func firstPage() async throws -> UInt {
        if let _firstPage { return _firstPage }

        guard let previous = await previous else { return try await chapter.firstPage() }

        _firstPage = try await previous.firstPage() + previous.pages()
        return _firstPage!
    }

    func pages() async throws -> UInt {
        if let _pages { return _pages }
        _pages = try await pdfInfo.pages()
        return _pages!
    }

    private func basename(`extension`: String) async -> String {
        let name = await fullTitle.replacingOccurrences(of: "/", with: "-")

        return await [
            chapter.data.fullTitle.replacingOccurrences(of: "/", with: "-"),
            "\(name).\(`extension`)"
        ].joined(separator: "/")
    }
}
