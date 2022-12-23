import Foundation
import libCommon

enum PSToPDFConverter {
    static func convert(book: Book, marksURL: URL, output: URL) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            let process = self.process(book: book, marksURL: marksURL, output: output)
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                continuation.resume(throwing: CirrusAMMGeneratorError.couldntConvertPStoPDF)
                return
            }
            
            continuation.resume(returning: ())
        }
    }
    
    private static func process(book: Book, marksURL: URL, output: URL) -> Process {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = [
            "gs", "-dBATCH", "-sDEVICE=pdfwrite",
            "-o", output.path
        ]
        process.arguments!.append(contentsOf: book.psPaths.map { $0.path })
        process.arguments!.append(marksURL.path)
        return process
    }
}
