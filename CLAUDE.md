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

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
