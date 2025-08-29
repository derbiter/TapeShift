# TapeShift v1.3.1

Fast, safe MiniDV/Hi8 → ProRes transcoding for macOS.

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

## Example Folder Structure
Before:
```
Footage/Scene1/file1.dv
Footage/Scene2/file2.avi
```

After:
```
Footage/Scene1/PRORES/file1.mov
Footage/Scene1/PROXIES/file1_proxy.mov
Footage/Scene2/PRORES/file2.mov
Footage/Scene2/PROXIES/file2_proxy.mov
```

## Safety Notes
- TapeShift never overwrites source files.
- Always test with `--dry-run` first to preview actions.
- The `--overwrite` flag replaces existing transcodes.
- Temporary files are guarded and will only be deleted safely within `PRORES/` or `PROXIES/`.

## License
This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
