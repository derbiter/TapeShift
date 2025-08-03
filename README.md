# TapeShift

**TapeShift** is a high-performance DV/MiniDV/Hi8 transcoder for macOS. It recursively scans a folder for `.dv` or `.avi` files, and creates high-quality ProRes masters and lightweight proxies in a Resolve-friendly folder structure.

## Features

- 🧠 Parallel ProRes and Proxy transcoding
- 🕹️ Interactive color profile selection (MiniDV, Hi8, PAL)
- 🎯 Deinterlacing with yadif
- 🗂️ Automatically creates `PRORES/` and `PROXIES/` folders
- 🔐 Safe `.tmp` file writing with guarded move
- ⏱️ Per-file timeout and max FAT32 duration guard
- 🔁 Retry support and dry-run mode
- 📄 Detailed logs and failure lists

## Usage

```bash
./tapeshift.sh --timeout 3600 --jobs 4 --threads 2
```

You will be prompted to select the source format to ensure the correct color space metadata is applied.

## Requirements

- macOS 15.5+
- FFmpeg installed (`brew install ffmpeg`)
