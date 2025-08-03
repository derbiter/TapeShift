## v1.2.2-dev - 2025-08-03

### Added
- Interactive prompt to select source tape format (MiniDV, Hi8, PAL).
- Automatically applies correct `-color_primaries`, `-color_trc`, and `-colorspace` settings based on selection.
- Retains support for dry-run, overwrite, retries, per-job timeout, deinterlacing, FAT32 duration guard, folder-structured output, and guarded `.tmp` file handling.

### Fixed
- Avoids invalid color profile errors (e.g., `bt470bg`) when encoding ProRes.
