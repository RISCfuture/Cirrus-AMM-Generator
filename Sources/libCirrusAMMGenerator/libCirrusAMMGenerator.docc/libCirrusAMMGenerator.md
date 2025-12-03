# ``libCirrusAMMGenerator``

Generate combined PDF documents from Cirrus Aircraft maintenance manuals.

## Overview

`libCirrusAMMGenerator` provides a Swift library for downloading and combining
Aircraft Maintenance Manuals (AMMs), Illustrated Parts Catalogs (IPCs), and
Wiring Manuals (WMs) from the Cirrus Service Centers website into a single PDF
with a properly formatted table of contents.

The library handles the complete pipeline:

1. **Downloading** the table of contents and individual PDF sections
2. **Converting** PDFs to PostScript to strip existing metadata
3. **Generating** new bookmark metadata for the combined document
4. **Combining** all sections into a single, navigable PDF

### Getting Started

The main entry point is the ``Book`` actor. Initialize it with a table of contents URL,
then call the pipeline methods in sequence:

```swift
import libCirrusAMMGenerator

let book = try await Book(
    tocURL: URL(string: "http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22/html/ammtoc.html")!,
    workingDirectory: URL(filePath: "./work"),
    filename: "SR22_AMM.pdf"
)

try await book.downloadPDFs()
try await book.convertToPS()
try await book.generatePDFMarks()
try await book.combinePDFs()

print("Generated PDF at: \(await book.outputURL.path)")
```

### Requirements

This library requires the following command-line tools to be installed:

- **GhostScript** (`gs`) - For combining PostScript files into PDF
- **Poppler** (`pdftops`, `pdfinfo`) - For PDF manipulation and metadata extraction

On macOS with Homebrew, install these with:

```bash
brew install ghostscript poppler
```

### Resumable Processing

All pipeline methods are designed to be resumable. Intermediate files are saved
to the working directory, so if the process is interrupted, simply run the same
code again and it will continue from where it left off.

## Topics

### Essentials

- ``Book``
- <doc:Pipeline>
- <doc:Dependencies>

### Error Handling

See `CirrusAMMGeneratorError` in the `libCommon` module for error types.
