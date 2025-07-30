# Changelog

All notable changes are documented here.

---

## [v1.2.0] - 2025-07-30
### Changed
- **Rebrand to TapeShift**. Script filename is now `tapeshift.sh`. No code changes from `v1.1.3`.

---

## [v1.1.3] - 2025-07-30
### Added
- `--jobs N` to control parallelism; default uses logical CPUs
- `--threads N` to control FFmpeg threads per job (default 2)
- `--clean-tmp-on-fail` (guarded) to remove `.mov.tmp` only in PRORES/PROXIES

### Improved
- Strong safety around temp files with `safe_rm_tmp()` (never touches sources)
- Non-destructive behavior when destination `.mov` path is a directory: skip & log
- More explicit deinterlacing: `yadif=mode=0:parity=auto:deint=all`
- Deterministic mapping: `-map 0:v:0 -map 0:a:? -map_metadata 0`
- SD NTSC color tags: `-movflags +use_metadata_tags+write_colr -colorspace smpte170m -color_primaries smpte170m -color_trc bt470bg`

---

## [v1.1.2] - 2025-07-29
### Fixed
- Corrected `mv`/`rm` syntax for `.mov.tmp` rename flow; kept `-f mov`; added non-destructive directory collision check.

---

## [v1.1.1] - 2025-07-29
### Fixed
- Added `-f mov` so FFmpeg muxes correctly when writing `.mov.tmp` files.

---

## [v1.1.0] - 2025-07-22
### Added
- Parallel job count based on logical CPU cores
- `-threads 2` per job
- Temporary output file protection and success logging
- Empty file check
- `--timeout` flag documented

---

## [v1.0.0] - 2025-07-21
### Added
- Baseline features: recursive scan; per-folder `PRORES`/`PROXIES`; deinterlacing; FAT32 duration cap; parallelization; `--timeout`, `--dry-run`, `--overwrite`, retry; graceful Ctrl+C; macOS 15.5 compatibility.
