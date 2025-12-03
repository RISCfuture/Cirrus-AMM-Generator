# ``libCommon``

Shared utilities and error types for the Cirrus AMM Generator.

## Overview

`libCommon` provides shared types used across the Cirrus AMM Generator project,
including the error type hierarchy and file system utilities.

This library is primarily intended for internal use by `libCirrusAMMGenerator`
and the `cirrus-amm-generator` command-line tool.

### Error Types

The `CirrusAMMGeneratorError` enum defines all errors that can occur during
PDF generation, including download failures, parsing errors, and conversion errors.

### File System Utilities

Extensions to `FileManager` for directory creation.
