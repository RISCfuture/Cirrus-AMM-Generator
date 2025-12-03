# ``CirrusAMMGenerator``

A command-line tool for generating combined Cirrus Aircraft maintenance manual PDFs.

## Overview

The `cirrus-amm-generator` command-line tool downloads and combines Aircraft
Maintenance Manuals (AMMs), Illustrated Parts Catalogs (IPCs), and Wiring
Manuals (WMs) from the Cirrus Service Centers website into a single PDF with
a properly formatted table of contents.

### Quick Start

```bash
# Build the tool
swift build

# Generate an SR22 AMM PDF
.build/debug/cirrus-amm-generator \
    http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22/html/ammtoc.html
```

The tool will download all PDFs, convert them, and combine them into a single
`AMM.pdf` file in the `work/` directory.

### Features

- **Resumable processing**: If interrupted, simply run again to continue
- **Concurrent downloads**: Multiple PDFs download simultaneously
- **Progress logging**: Use `-v` for detailed progress information
- **Customizable output**: Specify working directory and output filename

## Topics

### Getting Started

- <doc:Usage>

### Command Structure

- ``CirrusAMMGenerator/CirrusAMMGenerator``
