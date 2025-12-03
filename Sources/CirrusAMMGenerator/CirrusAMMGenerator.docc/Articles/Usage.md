# Command-Line Usage

Learn how to use the cirrus-amm-generator command-line tool.

## Overview

The `cirrus-amm-generator` tool combines individual PDF sections from the
Cirrus Service Centers website into a single, navigable PDF document.

## Installation

### Building from Source

```bash
git clone https://github.com/riscfuture/Cirrus-AMM-Generator.git
cd Cirrus-AMM-Generator
swift build -c release
```

The built executable is at `.build/release/cirrus-amm-generator`.

### Dependencies

Before running, install the required system dependencies:

```bash
brew install ghostscript poppler
```

Or use the included Brewfile:

```bash
brew bundle
```

## Basic Usage

```bash
cirrus-amm-generator <url>
```

Where `<url>` is the URL to the table of contents frame for the manual you
want to generate.

> Important: You must provide the URL to the table of contents **frame**
> specifically, not the main URL for the manual page.

## Command-Line Options

### Arguments

| Argument | Description |
|----------|-------------|
| `<url>` | The URL for the AMM/IPC/WM table of contents frame (required) |

### Options

| Option | Short | Description |
|--------|-------|-------------|
| `--work <path>` | `-w` | Working directory for temporary files (default: `./work`) |
| `--filename <name>` | `-f` | Output PDF filename (default: `AMM.pdf`) |
| `--verbose` | `-v` | Include progress information in output |
| `--help` | `-h` | Show help information |

## Examples

### Generate SR22 AMM

```bash
cirrus-amm-generator \
    http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22/html/ammtoc.html
```

### Generate with Custom Output

```bash
cirrus-amm-generator \
    -w ~/Documents/Cirrus \
    -f "SR22_G5_AMM.pdf" \
    -v \
    http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22+/html/ammtoc.html
```

### Generate SF50 Vision Jet IPC

```bash
cirrus-amm-generator \
    -f "SF50_IPC.pdf" \
    http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/ipc/SF50/html/ipctoc.html
```

## Known URLs

### SR20 Series

| Manual | URL |
|--------|-----|
| SR20 AMM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR20/html/ammtoc.html` |
| SR20 IPC | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR20/html/ipctoc.html` |
| SR20 WM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR20/html/wmtoc.html` |
| SR20 G6 AMM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR20+/html/ammtoc.html` |
| SR20 G6 IPC | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR20+/html/ipctoc.html` |
| SR20 G6 WM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR20+/html/wmtoc.html` |

### SR22 Series

| Manual | URL |
|--------|-----|
| SR22 AMM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22/html/ammtoc.html` |
| SR22 IPC | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR22/html/ipctoc.html` |
| SR22 WM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR22/html/wmtoc.html` |
| SR22 G5 AMM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22+/html/ammtoc.html` |
| SR22 G5 IPC | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR22+/html/ipctoc.html` |
| SR22 G5 WM | `http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR22+/html/wmtoc.html` |

### SF50 Vision Jet

| Manual | URL |
|--------|-----|
| SF50 AMM | `http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/amm/SF50/html/ammtoc.html` |
| SF50 IPC | `http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/ipc/SF50/html/ipctoc.html` |
| SF50 WM | `http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/wm/SF50/html/wmtoc.html` |

## Processing Time

The PDF generation process involves several time-consuming steps:

1. **Downloading PDFs**: Depends on network speed and manual size
2. **Converting to PostScript**: Relatively fast
3. **Combining with GhostScript**: The slowest step

> Note: GhostScript is notoriously slow. Combining hundreds of PostScript files
> can take several minutes. Plan accordingly.

## Resuming Interrupted Processing

All intermediate files are saved to the working directory. If processing is
interrupted for any reason:

1. Keep the working directory intact
2. Run the same command again
3. Already-completed work will be automatically skipped

This allows you to safely interrupt and resume the process as needed.

## Troubleshooting

### "pdfinfo: command not found"

Install Poppler:

```bash
brew install poppler
```

### "gs: command not found"

Install GhostScript:

```bash
brew install ghostscript
```

### Download Failures

If a PDF fails to download:

1. Check your network connection
2. Verify the URL is still valid on the Cirrus website
3. Delete any partially downloaded files in `work/pdfs/`
4. Re-run the command

### Conversion Errors

If a PDF fails to convert:

1. The source PDF may be corrupted
2. Delete the problematic file from `work/pdfs/`
3. Re-run to re-download and retry
