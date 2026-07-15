# Home Assistant Add-on: Prusa Connect RTSP Camera

## Overview

This add-on wraps [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) to enable streaming RTSP camera feeds to Prusa Connect for 3D printer monitoring through Home Assistant's configuration UI.

## Features

- **Multi-camera support**: Configure multiple cameras, each with its own Prusa Connect credentials
- **Password-protected tokens**: Prusa Connect tokens are hidden in the UI using the `password` schema type
- **Automated upstream sync**: GitHub Actions workflow to automatically pull updates from the upstream repository
- **Timelapse support**: Optional frame capture for timelapse video generation

---

## Implementation Plan

### 1. `config.yaml` - Add-on Configuration

Define metadata and array-based schema for multiple cameras:

```yaml
name: "Prusa Connect RTSP Camera"
version: "1.0.0"
slug: "prusa_connect_rtsp"
description: "Stream RTSP cameras to Prusa Connect for 3D printer monitoring"
arch: [aarch64, amd64, armhf, armv7, i386]

options:
  cameras:
    - name: "Printer 1"
      rtsp_url: ""
      token: ""
      fingerprint: ""
      upload_interval: 5
      timelapse_enabled: false
      timelapse_save_interval: 30
      timelapse_fps: 24

schema:
  cameras:
    - name: str
      rtsp_url: url
      token: password
      fingerprint: str
      upload_interval: "int(1,300)"
      timelapse_enabled: bool
      timelapse_save_interval: "int(10,3600)?"
      timelapse_fps: "int(1,60)?"

map:
  - share:rw
```

**Camera Configuration Fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | - | Friendly name for the camera/printer |
| `rtsp_url` | url | - | RTSP stream URL (e.g., `rtsp://user:pass@192.168.1.100/stream`) |
| `token` | password | - | Prusa Connect authentication token |
| `fingerprint` | string | - | Printer fingerprint (40-char hex) |
| `upload_interval` | int | 5 | Seconds between frame uploads (1-300) |
| `timelapse_enabled` | bool | false | Enable timelapse frame capture |
| `timelapse_save_interval` | int | 30 | Seconds between timelapse frames (10-3600) |
| `timelapse_fps` | int | 24 | FPS for generated timelapse videos (1-60) |

---

### 2. `Dockerfile` - Container Image

```dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-numpy \
    ffmpeg \
    jq

# Install Python packages
RUN pip3 install --no-cache-dir --break-system-packages \
    opencv-python-headless \
    requests \
    "numpy<2.0"

# Copy application files
COPY main.py /
COPY run.sh /

RUN chmod a+x /run.sh

CMD ["/run.sh"]
```

---

### 3. `run.sh` - Startup Script

Iterates over configured cameras and spawns a process for each:

```bash
#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json
PIDS=()

# Get number of cameras
CAMERAS_COUNT=$(jq '.cameras | length' $CONFIG_PATH)
bashio::log.info "Found ${CAMERAS_COUNT} camera(s) configured"

# Iterate over each camera
for (( i=0; i<CAMERAS_COUNT; i++ )); do
    CAMERA_NAME=$(jq -r ".cameras[$i].name" $CONFIG_PATH)
    
    # Export environment variables for Python script
    export RTSP_URL=$(jq -r ".cameras[$i].rtsp_url" $CONFIG_PATH)
    export TOKEN=$(jq -r ".cameras[$i].token" $CONFIG_PATH)
    export FINGERPRINT=$(jq -r ".cameras[$i].fingerprint" $CONFIG_PATH)
    export UPLOAD_INTERVAL=$(jq -r ".cameras[$i].upload_interval" $CONFIG_PATH)
    export ENABLE_TIMELAPSE=$(jq -r ".cameras[$i].timelapse_enabled" $CONFIG_PATH)
    export TIMELAPSE_SAVE_INTERVAL=$(jq -r ".cameras[$i].timelapse_save_interval // 30" $CONFIG_PATH)
    export TIMELAPSE_FPS=$(jq -r ".cameras[$i].timelapse_fps // 24" $CONFIG_PATH)
    export TIMELAPSE_DIR="/share/prusa_connect_rtsp/${CAMERA_NAME// /_}"
    
    mkdir -p "$TIMELAPSE_DIR"
    
    bashio::log.info "Starting camera: ${CAMERA_NAME}"
    python3 /main.py &
    PIDS+=($!)
done

# Wait for all processes
wait "${PIDS[@]}"
```

---

### 4. `main.py` & `requirements.txt` - Application Code

Copy directly from upstream repository:
- https://github.com/Knopersikcuo/Prusa-Connect-RTSP/blob/main/main.py
- https://github.com/Knopersikcuo/Prusa-Connect-RTSP/blob/main/requirements.txt

---

### 5. `.github/workflows/sync-upstream.yml` - Automated Updates

GitHub Actions workflow to sync upstream changes:

```yaml
name: Sync Upstream

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2:00 AM UTC
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Fetch upstream files
        run: |
          curl -sL https://raw.githubusercontent.com/Knopersikcuo/Prusa-Connect-RTSP/main/main.py -o main.py
          curl -sL https://raw.githubusercontent.com/Knopersikcuo/Prusa-Connect-RTSP/main/requirements.txt -o requirements.txt
      
      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "chore: sync upstream Prusa-Connect-RTSP"
          title: "🔄 Sync with upstream Prusa-Connect-RTSP"
          body: |
            Automated sync of `main.py` and `requirements.txt` from upstream.
            
            Source: [Knopersikcuo/Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP)
          branch: sync-upstream
          delete-branch: true
          labels: upstream-sync, automated
```

---

### 6. Documentation Files

#### `translations/en.yaml`

User-friendly labels and descriptions for the configuration UI.

#### `DOCS.md`

Installation and setup guide:
1. How to obtain Prusa Connect token and fingerprint
2. RTSP URL format examples
3. Multi-camera configuration examples
4. Timelapse usage and file locations

#### `README.md`

Repository documentation:
- Project overview and features
- Installation instructions (add repository to HA)
- Configuration reference
- Contributing guidelines

---

## File Structure

```
/
├── config.yaml                    # Add-on metadata and config schema
├── Dockerfile                     # Container build definition
├── run.sh                         # Startup script (multi-camera)
├── main.py                        # Upstream application (synced)
├── requirements.txt               # Python dependencies (synced)
├── CHANGELOG.md                   # Version history
├── DOCS.md                        # User documentation
├── README.md                      # Repository documentation
├── PLAN.md                        # This file
├── CLAUDE.md                      # Claude Code guidance
├── translations/
│   └── en.yaml                    # English translations
└── .github/
    └── workflows/
        └── sync-upstream.yml      # Upstream sync automation
```

---

## Design Decisions

### Multi-Camera Support
- Array-based configuration allows unlimited cameras
- Each camera runs as a separate background process
- Timelapse directories are separated by camera name

### Token Security
- Uses `password` schema type to mask tokens in HA UI
- Tokens only visible during initial entry

### Upstream Sync Strategy
- PR-based sync (not direct commit) for safety
- Allows testing changes before merging
- Daily schedule with manual trigger option

### Process Management
- Simple bash background processes (`&`)
- All cameras start together, fail independently
- Future improvement: Consider s6 supervisor for restart handling

---

## Next Steps

1. [ ] Create `config.yaml`
2. [ ] Create `Dockerfile`
3. [ ] Create `run.sh`
4. [ ] Copy `main.py` from upstream
5. [ ] Copy `requirements.txt` from upstream
6. [ ] Create `.github/workflows/sync-upstream.yml`
7. [ ] Create `translations/en.yaml`
8. [ ] Create `DOCS.md`
9. [ ] Create `README.md`
10. [ ] Create `CHANGELOG.md`
11. [ ] Test locally in Home Assistant
12. [ ] Push to GitHub repository
