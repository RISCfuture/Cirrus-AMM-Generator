import Foundation
import libCommon

enum PDFToPSConverter {
    static func convert(from input: URL, to output: URL) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            let process = self.process(input: input, output: output)
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
                return
            }
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                continuation.resume(throwing: CirrusAMMGeneratorError.couldntConvertPDFToPS(url: input))
                return
            }
            
            continuation.resume(returning: ())
        }
    }
    
    private static func process(input: URL, output: URL) -> Process {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/env")
        process.arguments = ["pdftops", input.path, output.path]
        return process
    }
}
