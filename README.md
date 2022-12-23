# Cirrus AMM Generator

This tool generates a combined PDF of all the Aircraft Maintenance Manuals
(AMMs), Illustrated Parts Catalogs (IPCs), and Wiring Manuals (WMs) on the
Cirrus Service Centers website. The final PDF will also have a well-formatted
table of contents using bookmark metadata.

This tool performs the following steps idempotently:

1. Downloads the list of URLs from a maintenance manual on the
   [Cirrus Service Centers web site](http://servicecenters.cirrusdesign.com/)
2. Downloads each PDF
3. Converts each PDF to PostScript (thus removing PDF metadata)
4. Generates table-of-contents bookmark metadata
5. Merges the PDFs, in the process applying the new TOC metadata

The results of each step are saved to the working directory. If the tool fails
on any one step, it can be re-run without performing already-completed work
again.

## Requirements

This tool requires Swift 5.7 with the Swift Package Manager. You must also have
the following binaries in your `$PATH`:

* `gs` (from Ghostscript)
* `pdftops`, `pdfinfo` (from Poppler)

If you are using Homebrew, you can install these dependencies by running
`brew bundle`.

## How to Run

Use `swift build` to build the `cirrus-amm-generator` tool. Running that tool
will show you usage instructions:

```
USAGE: cirrus-amm-generator <url> [--work <work>] [--filename <filename>] [--verbose]

ARGUMENTS:
  <url>                   The URL for the AMM/IPC/WM table of contents frame

OPTIONS:
  -w, --work <work>       The working directory for temporary files (resumable)
  -f, --filename <filename>
                          The name of the output PDF file (stored in working directory) (default: AMM.pdf)
  -v, --verbose           Include extra information in the output.
  -h, --help              Show help information.
```

Note that you must supply the URL to the _Table of Contents frame_ specifically,
_not_ the main URL for the page. A list of example URLs you can use:

* SR20 AMM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR20/html/ammtoc.html
* SR20 IPC: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR20/html/ipctoc.html
* SR20 WM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR20/html/wmtoc.html
* SR20 G6 AMM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR20+/html/ammtoc.html
* SR20 G6 IPC: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR20+/html/ipctoc.html
* SR20 G6 WM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR20+/html/wmtoc.html
* SR22 AMM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22/html/ammtoc.html
* SR22 IPC: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR22/html/ipctoc.html
* SR22 WM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR22/html/wmtoc.html
* SR22 G5 AMM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/amm/SR22+/html/ammtoc.html
* SR22 G5 IPC: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/ipc/SR22+/html/ipctoc.html
* SR22 G5 WM: http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/wm/SR22+/html/wmtoc.html
* SF50 AMM: http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/amm/SF50/html/ammtoc.html
* SF50 IPC: http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/ipc/SF50/html/ipctoc.html
* SF50 WM: http://servicecenters.cirrusdesign.com/tech_pubs/SF50/pdf/wm/SF50/html/wmtoc.html

**Important note:** GhostScript is the slowest thing ever produced by mankind.
Make sure you have one of the following at the ready to help pass the time:

* many coffees
* a large meal
* a plane you intend to fly around the world, spreading good vibes™

## Documentation

DocC documentation is available for the `libCirrusAMMGenerator` target. For
Xcode documentation, you can run

``` sh
swift package generate-documentation --target libCirrusAMMGenerator
```

to generate a docarchive at
`.build/plugins/Swift-DocC/outputs/libCirrusAMMGenerator.doccarchive`. You can
open this docarchive file in Xcode for browseable API documentation. Or, within
Xcode, open the libCirrusAMMGenerator package in Xcode and choose
**Build Documentation** from the **Product** menu.
