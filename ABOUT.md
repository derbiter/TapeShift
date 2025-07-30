# About TapeShift

**TapeShift** streamlines DV/MiniDV ingest on macOS, producing high-quality ProRes masters and lightweight proxies for editorial. It grew from a real-world archiving workflow where tapes were digitized to CF cards (FAT32), requiring a duration cap and robust error handling.

Goals:
- **Speed**: sensible parallelism + per-job threading
- **Safety**: no destructive deletes; guarded temp handling; skip on path collisions
- **Quality**: deinterlacing, SD NTSC color tags, consistent mapping
- **Convenience**: Resolve-ready folder structure, retry, dry-run, overwrite

Use **TapeShift** as a turnkey tool or adapt it for your archive process.
