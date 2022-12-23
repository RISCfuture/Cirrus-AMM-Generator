import Foundation

/// Errors that can occur in Cirrus AMM Generator.
public enum CirrusAMMGeneratorError: Error {
    
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
    public var errorDescription: String? {
        switch self {
            case .sectionNotDownloaded:
                return NSLocalizedString("A section was not downloaded.", comment: "error description")
            case .downloadFailed:
                return NSLocalizedString("A file could not be downloaded.", comment: "error description")
            case .couldntParsePDF:
                return NSLocalizedString("A PDF could not be parsed.", comment: "error description")
            case .couldntConvertPDFToPS:
                return NSLocalizedString("Failed to convert a PDF to PostScript.", comment: "error description")
            case .couldntConvertPStoPDF:
                return NSLocalizedString("Failed to convert a PostScript file to PDF.", comment: "error description")
            case .badTOC:
                return NSLocalizedString("The Table of Contents page could not be parsed.", comment: "error description")
            case .badEncoding:
                return NSLocalizedString("The Table of Contents page was in an unexpected encoding.", comment: "error description")
        }
    }
    
    public var failureReason: String? {
        switch self {
            case let .sectionNotDownloaded(name):
                let format = t("Expected the section “%@” to be downloaded, but it wasn’t.", comment: "failure reason")
                return String(format: format, name)
            case let .downloadFailed(url, response):
                if let response = response as? HTTPURLResponse {
                    let format = t("Response %d received when downloading “%@”.", comment: "failure reason")
                    return String(format: format, response.statusCode, url.absoluteString)
                } else {
                    let format = t("Unexpected response type when downloading “%@”.", comment: "failure reason")
                    return String(format: format, url.absoluteString)
                }
            case let .couldntParsePDF(url):
                let format = t("The file at “%@” doesn’t seem to be a valid PDF file.", comment: "failure reason")
                return String(format: format, url.path)
            case let .couldntConvertPDFToPS(url):
                let format = t("Poppler could not convert the file at “%@” from PDF to PostScript.", comment: "failure reason")
                return String(format: format, url.path)
            case .couldntConvertPStoPDF:
                return t("GhostScript could not recombine the PostScript files into a PDF file.", comment: "failure reason")
            case .badTOC:
                return t("The page had an unexpected HTML structure.", comment: "failure reason")
            case .badEncoding:
                return t("The HTML page was not ISO-8859-1 encoded.", comment: "failure reason")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
            case .sectionNotDownloaded:
                return t("Try removing the work/book.json file and re-running the Generator.", comment: "recovery suggestion")
            case .downloadFailed:
                return t("Verify that the Cirrus web site is accessible and the URL is correct. If not, try removing the “work/book.json” file and re-running the Generator.", comment: "recovery suggestion")
            case let .couldntParsePDF(url):
                let format = t("Verify the PDF is properly formatted. If not, try removing the “%@” file and re-running the generator. You can also try updating Poppler.", comment: "recovery suggestion")
                return String(format: format, url.path)
            case let .couldntConvertPDFToPS(url):
                let format = t("Verify the PDF is properly formatted. If not, try removing the “%@” file and re-running the generator. You can also try updating Poppler.", comment: "recovery suggestion")
                return String(format: format, url.path)
            case .couldntConvertPStoPDF:
                return t("Verify the files in “work/ps” are properly formatted. If not, try removing the “work” directory and re-running the generatror. You can also try updating GhostScript.", comment: "recovery suggestion")
            case .badTOC:
                return t("Verify the URL you are passing to the generator is correct. (It must be the URL to the TOC frame specifically, not the AMM page.) If so, Cirrus may have changed the format of their Table of Contents page, which will require modifying the code for the Generator.", comment: "recovery suggestion")
            case .badEncoding:
                return t("Verify the URL you are passing to the generator is correct. (It must be the URL to the TOC frame specifically, not the AMM page.) If so, Cirrus may have changed the format of their Table of Contents page, which will require modifying the code for the Generator.", comment: "recovery suggestion")
        }
    }
}

fileprivate func t(_ key: String, comment: String) -> String {
    return NSLocalizedString(key, bundle: Bundle.module, comment: comment)
}
