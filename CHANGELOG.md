# Changelog

## v1.3.1 - 2025-08-03
### Added
- Interactive tape format prompt (MiniDV, Hi8, PAL) for automatic color metadata.
- `--color-profile` flag to skip the prompt: `minidv`, `hi8`, or `pal`.
### Improved
- PAL encodes retry automatically with `smpte170m` if `bt470bg` color tags are rejected by the encoder.
