# TapeShift v1.3.1

TapeShift is a high‑performance Bash script for DV/MiniDV/Hi8 transcoding on macOS (tested on 15.5). It recursively scans for `.dv`/`.avi` and creates **ProRes masters** and **ProRes proxies** per source folder (`PRORES/`, `PROXIES/`).

## What’s new in v1.3.1
- Interactive **format prompt** (MiniDV, Hi8, PAL) that sets appropriate color metadata.
- PAL selection will auto‑fallback to `smpte170m` if your FFmpeg build rejects `bt470bg`.

## Features
- Parallel encodes with configurable `--jobs` and FFmpeg `--threads`
- Deinterlacing (yadif) and Resolve‑friendly folder structure
- Safe `.mov.tmp` writes and guarded rename
- Per‑file `--timeout` and FAT32 duration cap (`-t 00:19:45`)
- `--retry`, `--dry-run`, `--overwrite`, graceful Ctrl+C

## Usage
```bash
chmod +x tapeshift.sh
./tapeshift.sh --timeout 3600 --jobs 8 --threads 2
# You’ll be prompted: MiniDV / Hi8 / PAL
# Or skip the prompt:
./tapeshift.sh --color-profile minidv
./tapeshift.sh --color-profile hi8
./tapeshift.sh --color-profile pal
```

## Requirements
- macOS 15.5+
- FFmpeg (with prores_ks), e.g. `brew install ffmpeg`
