# The PDF Generation Pipeline

Understand how the library processes and combines PDFs from the Cirrus website.

## Overview

The Cirrus AMM Generator uses a multi-step pipeline to transform individual PDF
sections from the Cirrus Service Centers website into a single, navigable PDF
document. Each step is designed to be resumable, allowing interrupted processes
to continue where they left off.

![The PDF generation pipeline showing the flow from TOC download through final PDF output](pipeline.png)

## Pipeline Stages

### 1. Table of Contents Parsing

The pipeline begins by downloading and parsing the HTML table of contents page
from the Cirrus website. This page contains the hierarchical structure of the
manual:

- **Chapters** (e.g., "Chapter 05 - Time Limits/Maintenance Checks")
- **Sections** within each chapter, with links to individual PDF files

The parsed structure is saved to `book.json` in the working directory for
resumability.

### 2. PDF Download

Each section's PDF is downloaded concurrently from the Cirrus website. PDFs are
saved to the `pdfs/` subdirectory within the working directory, organized by
chapter.

If a PDF already exists, it will be skipped, allowing interrupted downloads
to resume.

### 3. PDF to PostScript Conversion

Downloaded PDFs are converted to PostScript format using Poppler's `pdftops`
utility. This conversion is necessary because:

- Source PDFs may contain their own bookmark metadata that would conflict
  with the combined document's table of contents
- PostScript is an intermediate format that can be cleanly recombined

Converted files are saved to the `ps/` subdirectory.

### 4. PDFMarks Generation

The library generates a pdfmarks file containing PostScript bookmark commands.
This file defines the table of contents structure that will appear in the
final PDF, including:

- Document title and author metadata
- Chapter bookmarks with page numbers
- Section bookmarks nested under their parent chapters

### 5. Final PDF Combination

GhostScript combines all PostScript files along with the pdfmarks file to
produce the final PDF. The result is a single document with:

- All sections merged in order
- A navigable table of contents sidebar
- Proper bookmark metadata for PDF readers

## Working Directory Structure

After a complete run, the working directory contains:

```
work/
├── book.json          # Cached table of contents data
├── pdfs/              # Downloaded PDF files
│   └── 05 Time Limits/
│       └── 05-10 General.pdf
├── ps/                # Converted PostScript files
│   └── 05 Time Limits/
│       └── 05-10 General.ps
├── pdfmarks           # Generated bookmark metadata
└── AMM.pdf            # Final combined PDF
```

## Error Recovery

If any stage fails, the library throws a `CirrusAMMGeneratorError` with
details about the failure. Common errors include:

- Network failures during download
- Malformed PDFs that cannot be parsed
- Conversion failures in Poppler or GhostScript

To recover, fix the underlying issue (e.g., delete a corrupted file) and
re-run the pipeline. Already-completed work will be skipped.
