# Changelog

## [1.3.5] - 2026-07-09

### Changed

- Supervisor now pulls prebuilt per-architecture images from GHCR instead of building the add-on locally on each device (added `image:` key). Installs are faster and no longer ship a build toolchain to every device.
- CI now tags pushed images with the add-on version (e.g. `1.3.5`) so the Supervisor can resolve the correct image, alongside the existing `latest`/commit tags.

## [1.3.4] - 2026-07-06

### Fixed

- Reverted the forced FFMPEG/RTSP-over-TCP backend from 1.3.3, which broke camera capture. OpenCV again selects its default backend.

## [1.3.3] - 2026-07-06

### Fixed

- Add-on no longer exits when the camera is briefly unreachable at startup (e.g. on Home Assistant boot). The initial connection test now retries with a delay (configurable via `CONNECT_RETRIES` / `CONNECT_RETRY_DELAY`) instead of quitting on the first failure, removing the need to manually restart.

### Known issues

- Forcing OpenCV's FFMPEG backend (also in this release) broke camera capture for some setups; fixed in 1.3.4.

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
