# CirrusAMMGeneratorError

Errors that can occur during PDF generation.

## Overview

`CirrusAMMGeneratorError` is a package-level enum that defines all errors
that may be thrown during the PDF generation process. Each error case provides
localized descriptions through conformance to `LocalizedError`.

## Error Cases

### Download Errors

- `downloadFailed(url:response:)` - An HTTP download failed

### Parsing Errors

- `badTOC` - The table of contents HTML was malformed
- `badEncoding` - The HTML page was not in the expected encoding
- `couldntParsePDF(url:)` - A PDF could not be parsed by Poppler

### Conversion Errors

- `couldntConvertPDFToPS(url:)` - PDF to PostScript conversion failed
- `couldntConvertPStoPDF` - PostScript to PDF conversion failed

### Processing Errors

- `sectionNotDownloaded(name:)` - A required PDF section was not downloaded
