import Foundation
import RegexBuilder
import libCommon

class PDFInfo {
    var url: URL
    
    private static let pagesRegex = Regex {
        Anchor.startOfLine
        "Pages:"
        OneOrMore(.whitespace)
        TryCapture {
            OneOrMore(.digit)
        } transform: { UInt($0) }
        Anchor.endOfLine
    }
    
    init(url: URL) {
        self.url = url
    }
    
    func pages() async throws -> UInt {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let (process, pipe) = process()
                try process.run()
                process.waitUntilExit()
                
                guard process.terminationReason == .exit && process.terminationStatus == 0 else {
                    continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
                    return
                }
                
                guard let output = try pipe.fileHandleForReading.readToEnd() else {
                    continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
                    return
                }
                
                guard let outputStr = String(data: output, encoding: .ascii) else {
                    continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
                    return
                }
                
                var found = false
                outputStr.enumerateLines(invoking: { line, stop in
                    let rx = #/^Pages:\s+(\d+)$/#
                    guard let match = line.wholeMatch(of: rx) else {
                        return
                    }
                    
                    guard let pages = UInt(match.1) else {
                        continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: self.url))
                        return
                    }
                    
                    continuation.resume(returning: pages)
                    found = true
                    stop = true
                })

                if !found {
                    continuation.resume(throwing: CirrusAMMGeneratorError.couldntParsePDF(url: url))
                }
            } catch {
                continuation.resume(throwing: error)
                return
            }
        }
    }
    
    private func process() -> (Process, Pipe) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = ["pdfinfo", url.path]
        process.standardOutput = pipe
        return (process, pipe)
    }
}

