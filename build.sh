#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$ROOT_DIR/client"
APP_NAME="openhare"

TARGET=""
BUILD_MODE="release"
RUN_PUB_GET=1
RUN_CODEGEN=0
RUN_PACKAGE=1
RUN_CLEAN=0

log() {
  printf '[build] %s\n' "$*"
}

warn() {
  printf '[build][warn] %s\n' "$*" >&2
}

err() {
  printf '[build][error] %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  ./build.sh [target] [options]

Targets:
  macos        Build Flutter desktop app for macOS
  linux        Build Flutter desktop app for Linux
  windows      Build installer for Windows (calls windows_build.ps1)

If target is omitted, it is auto-detected from the current OS.

Options:
  --debug             Build in debug mode (default: release)
  --release           Build in release mode
  --no-pub-get        Skip flutter pub get for project packages
  --codegen           Run code generation steps before build
  --no-package        Skip packaging artifacts (dmg/tar)
  --clean             Run flutter clean in client before build
  -h, --help          Show this help
EOF
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  local cmd="$1"
  command_exists "$cmd" || err "Required command not found: $cmd"
}

read_version() {
  local version
  version="$(awk '/^version:/{print $2; exit}' "$CLIENT_DIR/pubspec.yaml" | tr -d "\"'")"
  [[ -n "$version" ]] || err "Failed to read version from client/pubspec.yaml"
  echo "$version"
}

detect_target() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) err "Unsupported OS: $(uname -s). Please provide target explicitly." ;;
  esac
}

run_pub_get() {
  local dirs=(
    "$CLIENT_DIR"
    "$ROOT_DIR/pkg/db_driver"
    "$ROOT_DIR/pkg/sql_parser"
    "$ROOT_DIR/pkg/sql-editor"
  )
  for d in "${dirs[@]}"; do
    [[ -f "$d/pubspec.yaml" ]] || continue
    log "flutter pub get -> ${d#$ROOT_DIR/}"
    (cd "$d" && flutter pub get)
  done
}

run_codegen() {
  log "Running code generation in client"
  (
    cd "$CLIENT_DIR"
    dart run build_runner build --delete-conflicting-outputs
    flutter pub run flutter_launcher_icons
    flutter gen-l10n --verbose
  )
}

build_macos() {
  local version="$1"
  local arch
  arch="$(uname -m)"
  local flutter_mode_flag
  flutter_mode_flag="--$BUILD_MODE"

  log "Building macOS app ($BUILD_MODE)"
  (cd "$CLIENT_DIR" && flutter build macos "$flutter_mode_flag")

  local app_path="$CLIENT_DIR/build/macos/Build/Products/${BUILD_MODE^}/$APP_NAME.app"
  [[ -d "$app_path" ]] || err "Build output not found: $app_path"
  log "App built: $app_path"

  if [[ "$RUN_PACKAGE" -eq 0 ]]; then
    return
  fi

  if [[ "$BUILD_MODE" != "release" ]]; then
    warn "Skipping DMG package in debug mode"
    return
  fi

  local create_dmg
  if command_exists create-dmg; then
    create_dmg="$(command -v create-dmg)"
  elif [[ -x /opt/homebrew/bin/create-dmg ]]; then
    create_dmg="/opt/homebrew/bin/create-dmg"
  else
    warn "create-dmg not found, skip DMG package"
    return
  fi

  local dmg_name="$APP_NAME-$version-macos-$arch.dmg"
  rm -f "$ROOT_DIR/$dmg_name"
  log "Packaging DMG: $dmg_name"
  "$create_dmg" \
    --volname "$APP_NAME" \
    --window-size 600 400 \
    --icon-size 100 \
    --app-drop-link 450 150 \
    "$ROOT_DIR/$dmg_name" \
    "$app_path"
  log "DMG created: $ROOT_DIR/$dmg_name"
}

build_linux() {
  local version="$1"
  local arch
  arch="$(uname -m)"
  local flutter_mode_flag
  flutter_mode_flag="--$BUILD_MODE"

  log "Building Linux app ($BUILD_MODE)"
  (cd "$CLIENT_DIR" && flutter build linux "$flutter_mode_flag")

  local bundle_dir="$CLIENT_DIR/build/linux/x64/$BUILD_MODE/bundle"
  [[ -d "$bundle_dir" ]] || err "Build output not found: $bundle_dir"
  log "Bundle built: $bundle_dir"

  if [[ "$RUN_PACKAGE" -eq 0 ]]; then
    return
  fi

  local tar_name="$APP_NAME-$version-linux-$arch.tar.gz"
  rm -f "$ROOT_DIR/$tar_name"
  log "Packaging tar.gz: $tar_name"
  tar -C "$CLIENT_DIR/build/linux/x64/$BUILD_MODE" -czf "$ROOT_DIR/$tar_name" bundle
  log "Package created: $ROOT_DIR/$tar_name"
}

build_windows() {
  [[ "$BUILD_MODE" == "release" ]] || warn "windows_build.ps1 currently builds release only"
  local ps_cmd=""
  if command_exists pwsh; then
    ps_cmd="pwsh"
  elif command_exists powershell; then
    ps_cmd="powershell"
  fi
  [[ -n "$ps_cmd" ]] || err "PowerShell not found (pwsh/powershell)"

  local script="$ROOT_DIR/windows_build.ps1"
  [[ -f "$script" ]] || err "Script not found: $script"

  log "Building Windows installer via windows_build.ps1"
  "$ps_cmd" -ExecutionPolicy Bypass -File "$script"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      macos|linux|windows)
        TARGET="$1"
        shift
        ;;
      --debug)
        BUILD_MODE="debug"
        shift
        ;;
      --release)
        BUILD_MODE="release"
        shift
        ;;
      --no-pub-get)
        RUN_PUB_GET=0
        shift
        ;;
      --codegen)
        RUN_CODEGEN=1
        shift
        ;;
      --no-package)
        RUN_PACKAGE=0
        shift
        ;;
      --clean)
        RUN_CLEAN=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  [[ -n "$TARGET" ]] || TARGET="$(detect_target)"
  local version
  version="$(read_version)"

  log "Project root: $ROOT_DIR"
  log "Target: $TARGET"
  log "Mode: $BUILD_MODE"
  log "Version: $version"

  require_cmd flutter

  if [[ "$RUN_PUB_GET" -eq 1 ]]; then
    run_pub_get
  fi

  if [[ "$RUN_CODEGEN" -eq 1 ]]; then
    run_codegen
  fi

  if [[ "$RUN_CLEAN" -eq 1 ]]; then
    log "Running flutter clean"
    (cd "$CLIENT_DIR" && flutter clean)
  fi

  case "$TARGET" in
    macos) build_macos "$version" ;;
    linux) build_linux "$version" ;;
    windows) build_windows ;;
    *) err "Unsupported target: $TARGET" ;;
  esac

  log "Done"
}

main "$@"
