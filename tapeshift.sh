#!/bin/bash

set -e

# === DEFAULT CONFIGURATION ===
APP_NAME="TapeShift"
VERSION="v1.3.1"
TIMEOUT_DURATION=3600         # default: 1 hour
DRY_RUN=false
OVERWRITE=false
RETRY_MODE=false
RETRY_FILE=""
MAX_DURATION="00:19:45"       # hard limit for FAT32 split files
CPU_LIMIT="$(sysctl -n hw.logicalcpu)"   # default parallel slots = logical cores
FFMPEG_THREADS=2              # threads per ffmpeg job (auto-tuned if --jobs given)
CLEAN_TMP_ON_FAIL=false       # by default, keep tmp files on failure for inspection
COLOR_PROFILE=""              # minidv | hi8 | pal (if empty, prompt user)
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/tapeshift_errors_$TIMESTAMP.log"
FAILED_LIST="$SCRIPT_DIR/tapeshift_failed_files_$TIMESTAMP.txt"
SUCCESS_LIST="$SCRIPT_DIR/tapeshift_success_files_$TIMESTAMP.txt"
JOBS_COUNTED=0

# === CLEAN EXIT ON CTRL+C ===
cleanup() {
  echo ""
  echo "🛑 Interrupted. Cleaning up..."
  pkill -P $$ || true
  exit 1
}
trap cleanup SIGINT

# === SAFE TMP REMOVAL (never touches sources) ===
safe_rm_tmp() {
  local t="$1"
  # Only remove if it lives under PRORES/ or PROXIES/ and ends with .mov.tmp
  if [[ -n "$t" && ( "$t" == */PRORES/*.mov.tmp || "$t" == */PROXIES/*.mov.tmp ) ]]; then
    rm -f "$t"
  else
    echo "⚠️  Refusing to delete unexpected path: $t" | tee -a "$LOG_FILE"
  fi
}

# === CONTROL PARALLEL JOBS ===
wait_for_slot() {
  while [[ $(jobs -r | wc -l) -ge $CPU_LIMIT ]]; do
    sleep 0.5
  done
}

# === HELP ===
print_help() {
  cat <<EOF
$APP_NAME $VERSION
Usage: $(basename "$0") [options]

TapeShift – DV/MiniDV/Hi8 batch transcoder for macOS

Options:
  --dry-run                   Show what would run without encoding
  --overwrite                 Replace existing outputs
  --retry FILE                Retry only files listed in FILE
  --timeout SECONDS           Max seconds per ffmpeg invocation (default: ${TIMEOUT_DURATION})
  --jobs N                    Max parallel jobs (default: logical CPU count)
  --threads N                 Threads per ffmpeg job (default: ${FFMPEG_THREADS})
  --clean-tmp-on-fail         Remove .mov.tmp on failures (safe, guarded to PRORES/PROXIES only)
  --color-profile PROFILE     One of: minidv | hi8 | pal (skips prompt)
  -h | --help                 Show this help
EOF
}

# === PARSE FLAGS ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --overwrite) OVERWRITE=true ;;
    --retry) RETRY_MODE=true; RETRY_FILE="$2"; shift ;;
    --timeout) TIMEOUT_DURATION="$2"; shift ;;
    --jobs) CPU_LIMIT="$2"; shift ;;
    --threads) FFMPEG_THREADS="$2"; shift ;;
    --clean-tmp-on-fail) CLEAN_TMP_ON_FAIL=true ;;
    --color-profile) COLOR_PROFILE="$2"; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown option: $1"; print_help; exit 1 ;;
  esac
  shift
done

# Basic validation for numeric flags
is_number='^[0-9]+$'
if ! [[ "$TIMEOUT_DURATION" =~ $is_number ]]; then echo "❌ --timeout must be an integer"; exit 1; fi
if ! [[ "$CPU_LIMIT" =~ $is_number ]]; then echo "❌ --jobs must be an integer"; exit 1; fi
if ! [[ "$FFMPEG_THREADS" =~ $is_number ]]; then echo "❌ --threads must be an integer"; exit 1; fi
if [[ "$CPU_LIMIT" -lt 1 ]]; then CPU_LIMIT=1; fi
if [[ "$FFMPEG_THREADS" -lt 1 ]]; then FFMPEG_THREADS=1; fi

echo ""
$OVERWRITE && echo "⚠️  Overwrite enabled — existing files will be replaced."
$DRY_RUN && echo "🚫 Dry-run mode enabled — no actual encoding will occur."
$RETRY_MODE && echo "🔁 Retry mode enabled — processing files from: $RETRY_FILE"
echo "⏱️ Timeout set to: $TIMEOUT_DURATION seconds"
echo "🧠 Up to $CPU_LIMIT parallel jobs; $FFMPEG_THREADS thread(s) per ffmpeg job"
$CLEAN_TMP_ON_FAIL && echo "🧼 Will remove .mov.tmp on failures (guarded)" || echo "🗂️  Will KEEP .mov.tmp on failures for inspection"
echo ""

# === GATHER FILES ===
if [[ "$RETRY_MODE" = false ]]; then
  read -rp "Enter the full path to your input directory (where the .DV or .AVI files are): " INPUT_DIR
  if [[ ! -d "$INPUT_DIR" ]]; then
    echo "❌ Directory not found: $INPUT_DIR" | tee -a "$LOG_FILE"
    exit 1
  fi

  VIDEO_FILES=()
  while IFS= read -r -d '' file; do
    VIDEO_FILES+=("$file")
  done < <(find "$INPUT_DIR" -type f \( -iname '*.dv' -o -iname '*.avi' \) -print0)

  if [[ ${#VIDEO_FILES[@]} -eq 0 ]]; then
    echo "❌ No .dv or .avi files found in $INPUT_DIR or its subfolders." | tee -a "$LOG_FILE"
    exit 1
  fi
else
  if [[ ! -f "$RETRY_FILE" ]]; then
    echo "❌ Retry file not found: $RETRY_FILE"
    exit 1
  fi
  VIDEO_FILES=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    VIDEO_FILES+=("$line")
  done < "$RETRY_FILE"

  if [[ ${#VIDEO_FILES[@]} -eq 0 ]]; then
    echo "❌ No files listed in $RETRY_FILE"
    exit 1
  fi
fi

echo "📂 Found ${#VIDEO_FILES[@]} files to process."
echo ""

# === FOOTAGE FORMAT PROMPT (unless provided via --color-profile) ===
select_color_profile() {
  case "$1" in
    minidv|MINIDV|ntsc-dv|ntsc|dv)
      COLOR_PROFILE="minidv"
      ;;
    hi8|HI8|ntsc-hi8|hi-8)
      COLOR_PROFILE="hi8"
      ;;
    pal|PAL)
      COLOR_PROFILE="pal"
      ;;
    *)
      COLOR_PROFILE=""
      ;;
  esac

  if [[ -z "$COLOR_PROFILE" ]]; then
    echo "Select source tape format for color metadata:"
    echo "  1) MiniDV (NTSC)"
    echo "  2) Hi8 (NTSC)"
    echo "  3) PAL (DV/Hi8)"
    read -rp "Enter choice [1-3]: " choice
    case "$choice" in
      1) COLOR_PROFILE="minidv" ;;
      2) COLOR_PROFILE="hi8" ;;
      3) COLOR_PROFILE="pal" ;;
      *) echo "Invalid choice. Defaulting to MiniDV (NTSC)."; COLOR_PROFILE="minidv" ;;
    esac
  fi

  # Map to encoder-safe color args
  case "$COLOR_PROFILE" in
    minidv|hi8)
      COLOR_ARGS=(-movflags +use_metadata_tags+write_colr -colorspace smpte170m -color_primaries smpte170m -color_trc smpte170m)
      COLOR_ARGS_FALLBACK=("${COLOR_ARGS[@]}")  # same
      HUMAN_COLOR="NTSC (smpte170m)"
      ;;
    pal)
      COLOR_ARGS=(-movflags +use_metadata_tags+write_colr -colorspace bt470bg -color_primaries bt470bg -color_trc bt470bg)
      COLOR_ARGS_FALLBACK=(-movflags +use_metadata_tags+write_colr -colorspace smpte170m -color_primaries smpte170m -color_trc smpte170m)
      HUMAN_COLOR="PAL (bt470bg, fallback smpte170m)"
      ;;
  esac

  echo "🎚  Color profile: $COLOR_PROFILE → $HUMAN_COLOR"
}

select_color_profile "$COLOR_PROFILE"

# === TRANSCODING FUNCTION ===
transcode_file() {
  local f="$1"
  local base_name source_dir prores_dir proxies_dir output_prores output_proxy

  base_name="$(basename "${f%.*}")"
  source_dir="$(dirname "$f")"
  prores_dir="$source_dir/PRORES"
  proxies_dir="$source_dir/PROXIES"
  output_prores="$prores_dir/${base_name}.mov"
  output_proxy="$proxies_dir/${base_name}.mov"

  mkdir -p "$prores_dir" "$proxies_dir"

  if [[ "$DRY_RUN" = true ]]; then
    echo "🔎 Dry-run — would transcode: $f"
    echo "    → $output_prores"
    echo "    → $output_proxy"
    return
  fi

  if [[ ! -s "$f" ]]; then
    echo "❌ Skipping empty file: $f" | tee -a "$FAILED_LIST"
    return
  fi

  echo "🎬 [$((++JOBS_COUNTED))/${#VIDEO_FILES[@]}] Processing: $(basename "$f")"

  # Common mapping & metadata
  MAP_ARGS=(-map 0:v:0 -map 0:a:? -map_metadata 0)

  # Helper: run ffmpeg once with COLOR_ARGS, and if it fails (non-timeout) and a fallback exists, try fallback
  run_ffmpeg_with_color() {
    # $1 = 'prores' or 'proxy'
    # $2 = input file
    # $3 = output tmp path
    # $4 = vf string
    # $5 = prores profile (e.g., 3 or 0)
    local label="$1"
    local in="$2"
    local outtmp="$3"
    local vf="$4"
    local prof="$5"

    timeout "$TIMEOUT_DURATION" ffmpeg -hide_banner -loglevel error -y \
      -threads "$FFMPEG_THREADS" \
      -i "$in" \
      -t "$MAX_DURATION" \
      -vf "$vf" \
      "${MAP_ARGS[@]}" \
      -c:v prores_ks -profile:v "$prof" \
      -c:a pcm_s16le \
      "${COLOR_ARGS[@]}" \
      -f mov "$outtmp"
    local rc=$?

    if [[ $rc -eq 124 ]]; then
      echo "❌ Timeout after $TIMEOUT_DURATION sec ($label): $in" | tee -a "$FAILED_LIST"
      [[ "$CLEAN_TMP_ON_FAIL" = true ]] && safe_rm_tmp "$outtmp"
      return $rc
    elif [[ $rc -ne 0 ]]; then
      # Try fallback if different from primary
      if [[ "${COLOR_ARGS_FALLBACK[*]}" != "${COLOR_ARGS[*]}" ]]; then
        echo "↩️  Retrying $label with fallback color tags..." | tee -a "$LOG_FILE"
        timeout "$TIMEOUT_DURATION" ffmpeg -hide_banner -loglevel error -y \
          -threads "$FFMPEG_THREADS" \
          -i "$in" \
          -t "$MAX_DURATION" \
          -vf "$vf" \
          "${MAP_ARGS[@]}" \
          -c:v prores_ks -profile:v "$prof" \
          -c:a pcm_s16le \
          "${COLOR_ARGS_FALLBACK[@]}" \
          -f mov "$outtmp"
        rc=$?
      fi
    fi

    return $rc
  }

  # === ProRes Output ===
  if [[ ! -f "$output_prores" || "$OVERWRITE" = true ]]; then
    run_ffmpeg_with_color "ProRes" "$f" "${output_prores}.tmp" "yadif=mode=0:parity=auto:deint=all" 3
    result=$?

    if [[ $result -eq 124 ]]; then
      return
    elif [[ $result -ne 0 ]]; then
      echo "❌ ProRes failed: $f" | tee -a "$FAILED_LIST"
      [[ "$CLEAN_TMP_ON_FAIL" = true ]] && safe_rm_tmp "${output_prores}.tmp"
      return
    else
      if [[ -d "$output_prores" ]]; then
        echo "❌ Expected file but found directory at $output_prores — skipping." | tee -a "$FAILED_LIST"
        [[ "$CLEAN_TMP_ON_FAIL" = true ]] && safe_rm_tmp "${output_prores}.tmp"
        return
      else
        mv -f "${output_prores}.tmp" "$output_prores"
        echo "✅ ProRes done: $output_prores"
      fi
    fi
  else
    echo "⚠️  Skipping ProRes (exists): $output_prores"
  fi

  # === Proxy Output ===
  if [[ ! -f "$output_proxy" || "$OVERWRITE" = true ]]; then
    run_ffmpeg_with_color "Proxy" "$f" "${output_proxy}.tmp" "yadif=mode=0:parity=auto:deint=all,scale=640:-2" 0
    result=$?

    if [[ $result -eq 124 ]]; then
      return
    elif [[ $result -ne 0 ]]; then
      echo "❌ Proxy failed: $f" | tee -a "$FAILED_LIST"
      [[ "$CLEAN_TMP_ON_FAIL" = true ]] && safe_rm_tmp "${output_proxy}.tmp"
      return
    else
      if [[ -d "$output_proxy" ]]; then
        echo "❌ Expected file but found directory at $output_proxy — skipping." | tee -a "$FAILED_LIST"
        [[ "$CLEAN_TMP_ON_FAIL" = true ]] && safe_rm_tmp "${output_proxy}.tmp"
        return
      else
        mv -f "${output_proxy}.tmp" "$output_proxy"
        echo "✅ Proxy done: $output_proxy"
      fi
    fi
  else
    echo "⚠️  Skipping Proxy (exists): $output_proxy"
  fi

  echo "$f" >> "$SUCCESS_LIST"
}

# === TRANSCODING LOOP (PARALLELIZED) ===
for f in "${VIDEO_FILES[@]}"; do
  wait_for_slot
  transcode_file "$f" &
done

wait  # wait for all background jobs

# === SUMMARY ===
echo ""
if [[ ! -s "$FAILED_LIST" ]]; then
  echo "✅ All files transcoded successfully!"
else
  echo "⚠️  Some files failed. See:"
  echo "   🔁 Retry list: $FAILED_LIST"
  echo "   🪵 Log file:   $LOG_FILE"
  cat "$FAILED_LIST"
fi
