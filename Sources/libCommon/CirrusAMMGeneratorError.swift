import Foundation

/// Errors that can occur in Cirrus AMM Generator.
package enum CirrusAMMGeneratorError: Error {

    /**
     A downloaded PDF file is missing for a section.
     - Parameter name: The name of the section.
     */
    case sectionNotDownloaded(name: String)

    /**
     An HTTP download failed.
     - Parameter url: The URL that failed to download.
     - Parameter response: The failed response.
     */
    case downloadFailed(url: URL, response: URLResponse)

    /**
     A PDF couldn’t be parsed by Poppler.
     - Parameter url: The location of the PDF file.
     */
    case couldntParsePDF(url: URL)

    /**
     A PDF couldn’t be converted to PostScript by Poppler.
     - Parameter url: The location of the PDF file.
     */
    case couldntConvertPDFToPS(url: URL)

    /**
     The PostScript files couldn’t be recombined into a PDF file by GhostScript.
     */
    case couldntConvertPStoPDF

    /// The Table of Contents HTML file was in an unexpected format.
    case badTOC

    /// The Table of Contents HTML file was not ISO-8859-1 encoded.
    case badEncoding
}

extension CirrusAMMGeneratorError: LocalizedError {
    package var errorDescription: String? {
        switch self {
            case .sectionNotDownloaded:
                return String(localized: "A section was not downloaded.", comment: "error description")
            case .downloadFailed:
                return String(localized: "A file could not be downloaded.", comment: "error description")
            case .couldntParsePDF:
                return String(localized: "A PDF could not be parsed.", comment: "error description")
            case .couldntConvertPDFToPS:
                return String(localized: "Failed to convert a PDF to PostScript.", comment: "error description")
            case .couldntConvertPStoPDF:
                return String(localized: "Failed to convert a PostScript file to PDF.", comment: "error description")
            case .badTOC:
                return String(localized: "The Table of Contents page could not be parsed.", comment: "error description")
            case .badEncoding:
                return String(localized: "The Table of Contents page was in an unexpected encoding.", comment: "error description")
        }
    }

    package var failureReason: String? {
        switch self {
            case let .sectionNotDownloaded(name):
                return String(localized: "Expected the section “\(name)” to be downloaded, but it wasn’t.", comment: "failure reason")
            case let .downloadFailed(url, response):
                if let response = response as? HTTPURLResponse {
                    return String(
                        localized: "Response \(response.statusCode) received when downloading “\(url.absoluteString)”.",
                        comment: "failure reason"
                    )
                }
                return String(localized: "Unexpected response type when downloading “\(url.absoluteString)”.", comment: "failure reason")
            case let .couldntParsePDF(url):
                return String(localized: "The file at “\(url.path)” doesn’t seem to be a valid PDF file.", comment: "failure reason")
            case let .couldntConvertPDFToPS(url):
                return String(localized: "Poppler could not convert the file at “\(url.path)” from PDF to PostScript.", comment: "failure reason")
            case .couldntConvertPStoPDF:
                return String(localized: "GhostScript could not recombine the PostScript files into a PDF file.", comment: "failure reason")
            case .badTOC:
                return String(localized: "The page had an unexpected HTML structure.", comment: "failure reason")
            case .badEncoding:
                return String(localized: "The HTML page was not ISO-8859-1 encoded.", comment: "failure reason")
        }
    }

    package var recoverySuggestion: String? {
        switch self {
            case .sectionNotDownloaded:
                return String(localized: "Try removing the work/book.json file and re-running the Generator.", comment: "recovery suggestion")
            case .downloadFailed:
                return String(localized: "Verify that the Cirrus web site is accessible and the URL is correct. If not, try removing the “work/book.json” file and re-running the Generator.", comment: "recovery suggestion")
            case let .couldntParsePDF(url):
                return String(localized: "Verify the PDF is properly formatted. If not, try removing the “\(url.path)” file and re-running the generator. You can also try updating Poppler.", comment: "recovery suggestion")
            case let .couldntConvertPDFToPS(url):
                return String(localized: "Verify the PDF is properly formatted. If not, try removing the “\(url.path)” file and re-running the generator. You can also try updating Poppler.", comment: "recovery suggestion")
            case .couldntConvertPStoPDF:
                return String(localized: "Verify the files in “work/ps” are properly formatted. If not, try removing the “work” directory and re-running the generatror. You can also try updating GhostScript.", comment: "recovery suggestion")
            case .badTOC:
                return String(localized: "Verify the URL you are passing to the generator is correct. (It must be the URL to the TOC frame specifically, not the AMM page.) If so, Cirrus may have changed the format of their Table of Contents page, which will require modifying the code for the Generator.", comment: "recovery suggestion")
            case .badEncoding:
                return String(localized: "Verify the URL you are passing to the generator is correct. (It must be the URL to the TOC frame specifically, not the AMM page.) If so, Cirrus may have changed the format of their Table of Contents page, which will require modifying the code for the Generator.", comment: "recovery suggestion")
        }
    }
}
