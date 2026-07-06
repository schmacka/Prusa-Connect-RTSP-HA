# Changelog

## [1.3.3] - 2026-07-06

### Fixed

- Add-on no longer exits when the camera is briefly unreachable at startup (e.g. on Home Assistant boot). The initial connection test now retries with a delay (configurable via `CONNECT_RETRIES` / `CONNECT_RETRY_DELAY`) instead of quitting on the first failure, removing the need to manually restart.
- RTSP capture now forces OpenCV's FFMPEG backend with TCP transport, eliminating the `GStreamer warning: missing plugin: Real Time Streaming Protocol (RTSP) source` errors and improving connection reliability.

## [1.3.2] - 2026-07-01

### Fixed

- Install failure on add-on build: `paho-mqtt` now installs from the Alpine `py3-paho-mqtt` package instead of pip (`--break-system-packages`)

### Changed

- `BUILD_FROM` is arch-neutral again (removed hardcoded amd64 default); added `build.yaml` so the Supervisor selects the correct per-architecture base image

## [1.3.1] - 2026-02-26

### Added

- MQTT camera discovery: cameras now appear as Home Assistant camera entities
- Auto-detect MQTT broker from Home Assistant services
- DOCS.md in addon directory for proper documentation link in HA UI

### Fixed

- Timelapse frames no longer wiped on addon restart; cleanup only after successful video creation
- "Weitere Informationen" link now points to addon documentation instead of GitHub

### Changed

- Removed `homeassistant_api` for improved security rating

## [1.2.0] - 2025-12-08

### Added

- Detailed logging showing camera configuration on startup
- Python output prefixed with camera name for multi-camera setups
- Visual separators in logs for easier reading

## [1.1.0] - 2025-12-08

### Added

- Auto-generate camera fingerprints (no manual setup required)
- Fingerprints persist in `/data/fingerprints/` across restarts

### Changed

- Fingerprint field is now optional in configuration
- Simplified documentation and setup process

## [1.0.0] - 2025-12-08

### Added

- Initial release
- Multi-camera support with array-based configuration
- Password-protected token fields in Home Assistant UI
- Timelapse frame capture and video generation
- GitHub Actions workflow for automated upstream sync
- Full documentation and translations
