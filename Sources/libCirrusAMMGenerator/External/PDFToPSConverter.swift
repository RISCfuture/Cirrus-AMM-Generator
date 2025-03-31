import Foundation
import libCommon

enum PDFToPSConverter {
    // swiftlint:disable:next redundant_void_return
    static func convert(from input: URL, to output: URL) async throws -> Void {
        // swiftlint:disable:next return_value_from_void_function
        return try await withCheckedThrowingContinuation { continuation in
            let process = process(input: input, output: output)
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
        process.executableURL = URL(filePath: "/usr/bin/env", directoryHint: .notDirectory)
        process.arguments = ["pdftops", input.path, output.path]
        return process
    }
}
