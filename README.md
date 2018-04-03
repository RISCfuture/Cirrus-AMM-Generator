# Cirrus AMM Generator

This script generates a combined PDF of all the SR22 Aircraft Maintenance
Manuals on the Cirrus website. The final PDF will also have a well-formatted
table of contents using bookmark metadata.

This script performs the following steps idempotently:

1. Downloads the list of URLs from the [Cirrus web site](http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/AMM/SR22/html/ammtoc.html)
2. Downloads each PDF
3. Converts each PDF to PostScript (thus removing PDF metadata)
4. Generates table-of-contents bookmark metadata
5. Merges the PDFs, in the process applying the new TOC metadata

The results of each step are saved to the file system. If the script fails on
any one step, it can be re-run without performing already-completed work again.

## Requirements

This script requires at least Ruby 2.0 (2.5.1 targeted) and the Bundler gem.
You must also have the following binaries in your `$PATH`:

* `gs` (from Ghostscript)
* `pdftops`, `pdfinfo` (from Poppler)

If you are using Homebrew, you can install
these dependencies by running `brew bundle`.

## How to Run

To run, simply run `bundle install` to install dependencies, and then execute
`ruby run.rb`. The script will update you as to its progress, and then tell you
where it deposited the finished PDF.


**Important note:** GhostScript is the slowest thing ever produced by mankind.
Make sure you have one of the following at the ready to help pass the time:

* many coffees
* a large meal
* a plane you intend to fly around the world, spreading good vibes™

## Documentation

Generate HTML documentation by running `yard` on the command line. Generated
documentation is saved inthe `doc` directory.
