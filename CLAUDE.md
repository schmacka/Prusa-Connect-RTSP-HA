# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Home Assistant addon that wraps the [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) Python application. It enables users to stream RTSP camera feeds to Prusa Connect for 3D printer monitoring through Home Assistant's configuration UI.

## Architecture

### Core Components

**Base Application (Prusa-Connect-RTSP)**
- Python application using OpenCV to capture RTSP streams
- Uploads frames to Prusa Connect at configurable intervals
- Generates timelapse videos from captured frames
- Manages disk space by removing old frames
- Dependencies: Python 3.7+, opencv-python, requests, NumPy (<2.0)

**Home Assistant Addon Wrapper**
- Exposes all configuration options through HA's config UI
- Configuration stored in `/data/options.json` within the container
- User provides: Prusa Connect token, printer fingerprint, RTSP URL, and timing settings

### Required Files Structure

```
/
├── config.yaml          # Addon metadata and configuration schema
├── Dockerfile           # Container image definition
├── run.sh              # Startup script that launches the Python app
├── CHANGELOG.md        # Version history
├── DOCS.md            # User-facing documentation
├── README.md          # Repository documentation
└── translations/
    └── en.yaml        # English localization
```

## Configuration Schema

The `config.yaml` must define:

**Required Metadata:**
- `name`: Display name
- `version`: Semantic version matching Docker tag
- `slug`: Unique URI-friendly identifier
- `description`: Brief overview
- `arch`: Supported architectures (aarch64, amd64, armhf, armv7, i386)

**User Configuration Fields (options/schema):**
- `prusa_token`: Prusa Connect authentication token (password type)
- `printer_fingerprint`: Unique printer identifier (string)
- `rtsp_url`: Camera stream URL with optional embedded credentials (url type)
- `upload_interval`: Seconds between frame uploads (int, default: 5)
- `timelapse_enabled`: Enable timelapse generation (bool, default: true)
- Additional settings from base application as needed

### Accessing Configuration

In `run.sh`, read user settings from `/data/options.json`:
```bash
CONFIG_PATH=/data/options.json
PRUSA_TOKEN=$(jq --raw-output '.prusa_token // empty' $CONFIG_PATH)
PRINTER_FINGERPRINT=$(jq --raw-output '.printer_fingerprint // empty' $CONFIG_PATH)
RTSP_URL=$(jq --raw-output '.rtsp_url // empty' $CONFIG_PATH)
```

Alternatively, use the Bashio helper library for cleaner syntax.

## Development Commands

### Local Testing
1. Copy addon files to Home Assistant's `/addons/` directory (accessible via Samba/SSH)
2. Navigate to Settings → Add-ons → Add-on Store
3. Click "Check for updates" to refresh local addon list
4. Install from "Local add-ons" section
5. View logs via the "Logs" tab

### Validation
- Ensure `config.yaml` uses valid YAML syntax (use YAML linter)
- Verify all files use UNIX line endings (LF), not Windows (CRLF)
- Check Home Assistant Supervisor logs for validation errors

### Building
The Dockerfile should:
- Use `ARG BUILD_FROM` and `FROM $BUILD_FROM` for multi-arch support
- Install Python dependencies: `apk add --no-cache python3 py3-pip`
- Install Python packages: `pip3 install opencv-python-headless requests numpy`
- Copy and make run.sh executable: `RUN chmod a+x /run.sh`
- Set CMD to execute run.sh: `CMD ["/run.sh"]`

## Key Technical Details

### Base Application Behavior
- Creates fresh HTTP sessions and camera connections per frame (prevents connection reuse issues)
- Implements retry logic and rate-limit detection
- Requires environment variables for configuration (map from HA options)
- Performs automatic JPEG encoding and frame resizing for timelapses

### Home Assistant Integration
- User configuration exposed through HA UI (no manual file editing)
- Add-ons run as isolated Docker containers
- Use `map` in config.yaml if access to shared directories is needed (config, ssl, backup, share, media)
- Consider `ingress: true` if adding a web UI component

### Important Constraints
- NumPy version must be <2.0 for compatibility
- OpenCV headless variant recommended for containers (no GUI dependencies)
- RTSP URLs can embed credentials: `rtsp://user:pass@camera-ip:port/stream`

### URL to test rtsp camera stream
- Use the following URL to test if the camera stream works and can be used to upload images.
rtsp://thingino:thingino@192.168.2.74:554/ch0

## Task tracking

Tasks live in the Obsidian vault: `~/Developer/vault/Projekte/Prusa-Connect-RTSP-HA/Tasks.md`
(format: `~/Developer/vault/Vault-Map.md`, section *Tasks*). beads (`bd`) was
retired on 2026-11-27: don't create or update beads or run `bd`. `.beads/` stays
in the repo as read-only history.
