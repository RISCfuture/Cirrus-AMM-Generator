# External Dependencies

Install the required command-line tools for PDF processing.

## Overview

The Cirrus AMM Generator library relies on two external command-line tools for
PDF manipulation. These tools must be installed and available in your `$PATH`
before using the library.

## Required Tools

### GhostScript

GhostScript is used to combine multiple PostScript files into a single PDF
document with bookmark metadata.

**Required binary:** `gs`

**Used by:** ``Book/combinePDFs()``

### Poppler

Poppler provides utilities for PDF manipulation and metadata extraction.

**Required binaries:**
- `pdftops` - Converts PDF files to PostScript format
- `pdfinfo` - Extracts metadata (page count) from PDF files

**Used by:** ``Book/convertToPS()``, ``Book/generatePDFMarks()``

## Installation

### macOS with Homebrew

The easiest way to install these dependencies on macOS is via Homebrew:

```bash
brew install ghostscript poppler
```

Or use the included Brewfile:

```bash
brew bundle
```

### macOS with MacPorts

```bash
sudo port install ghostscript poppler
```

### Linux (Debian/Ubuntu)

```bash
sudo apt-get install ghostscript poppler-utils
```

### Linux (Fedora/RHEL)

```bash
sudo dnf install ghostscript poppler-utils
```

## Verifying Installation

After installation, verify the tools are available:

```bash
gs --version
pdftops -v
pdfinfo -v
```

All commands should print version information without errors.

## Performance Notes

GhostScript is the slowest component of the pipeline. Combining hundreds of
PostScript files into a single PDF can take several minutes. Plan accordingly
and consider running the process when you have time to wait.
