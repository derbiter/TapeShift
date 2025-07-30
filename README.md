# TapeShift

**TapeShift** is a fast, safe batch transcoding tool for DV/MiniDV footage on macOS (tested on macOS 15.5 / Apple Silicon). It creates **ProRes** masters and **ProRes proxies** in DaVinci Resolve–friendly folders, with deinterlacing and SD NTSC color tags.

---

## ✨ Features

- Recursive scan for `.dv`/`.avi`
- Output per source folder: `PRORES/` and `PROXIES/`
- ProRes HQ masters + ProRes Proxy files
- Deinterlacing (`yadif=mode=0:parity=auto:deint=all`)
- SD NTSC 601 color metadata in MOV
- Duration cap for FAT32-split captures (`-t 00:19:45`)
- Parallel processing with configurable job count
- Per-job FFmpeg threads configurable
- Timeout per encode, retry mode, dry-run, overwrite
- Safe temp-file handling (`.mov.tmp`) with opt‑in cleanup
- Graceful Ctrl+C

---

## 🧰 Requirements

- macOS 15.5 (24F74) or later
- FFmpeg 6.x/7.x with `prores_ks`
- Apple Silicon recommended

---

## 🚀 Usage

```bash
chmod +x tapeshift.sh

# Basic run (interactive input dir prompt)
./tapeshift.sh

# Custom timeout (seconds), jobs, threads
./tapeshift.sh --timeout 3600 --jobs 8 --threads 2

# Overwrite existing outputs
./tapeshift.sh --overwrite

# Dry run (no encoding)
./tapeshift.sh --dry-run

# Retry failed set
./tapeshift.sh --retry path/to/tapeshift_failed_files_*.txt

# Opt-in: clean *.mov.tmp (guarded to PRORES/PROXIES only)
./tapeshift.sh --clean-tmp-on-fail
```

> **Note:** TapeShift writes success/failure logs next to the script:  
> - `tapeshift_errors_<timestamp>.log`  
> - `tapeshift_failed_files_<timestamp>.txt`  
> - `tapeshift_success_files_<timestamp>.txt`

---

## 📁 Output Layout

```
/path/to/TapeFolder/
├── 00_0001.DV
├── PRORES/
│   └── 00_0001.mov
└── PROXIES/
    └── 00_0001.mov
```

---

## ⚙️ Options

| Flag                | Description |
|---------------------|-------------|
| `--dry-run`         | Show what would run without encoding |
| `--overwrite`       | Replace existing outputs |
| `--retry FILE`      | Retry only files listed in `FILE` |
| `--timeout SECONDS` | Max seconds per FFmpeg process (default: 3600) |
| `--jobs N`          | Max parallel jobs (default: logical CPU count) |
| `--threads N`       | Threads per FFmpeg job (default: 2) |
| `--clean-tmp-on-fail` | Remove `.mov.tmp` on failure (guarded to PRORES/PROXIES only) |
| `-h, --help`        | Show help |

---

## 🔒 Safety

- **No destructive deletes.** Any cleanup is limited to `.mov.tmp` files **inside `PRORES/` or `PROXIES/`** only, and only when explicitly enabled with `--clean-tmp-on-fail`.
- If a destination `.mov` path is unexpectedly a **directory**, TapeShift **skips and logs**.

---

## 📦 Versioning

See `CHANGELOG.md`. Earlier versions were named `dv_transcode.sh`. The project has been rebranded to **TapeShift** as of `v1.2.0` (no code changes from `v1.1.3` aside from the filename and docs).
