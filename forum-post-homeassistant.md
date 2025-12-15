# New Add-on: Prusa Connect RTSP Camera - Stream Any RTSP Camera to Prusa Connect

**Recommended Title:** New Add-on: Prusa Connect RTSP Camera - Stream Any RTSP Camera to Prusa Connect

**Recommended Category:** Add-ons (or Third Party Add-ons)

---

## Overview

I've created a Home Assistant add-on that makes it easy to stream RTSP camera feeds to Prusa Connect for 3D printer monitoring. This is a wrapper around the excellent [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) project by Knopersikcuo, packaged as a native Home Assistant add-on with full UI configuration support.

## Features

- **Easy Configuration**: Configure everything through Home Assistant's UI - no manual file editing
- **Multi-camera Support**: Monitor multiple printers with different cameras
- **Secure Credentials**: Prusa Connect tokens are password-protected in the UI
- **Timelapse Support**: Optional frame capture for timelapse video generation
- **Multi-architecture**: Supports aarch64, amd64, armhf, armv7, and i386

## Installation

Click the button below to add the repository to your Home Assistant instance:

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fschmacka%2Fhomeassistant-addons)

Or manually:
1. Navigate to **Settings** > **Add-ons** > **Add-on Store**
2. Click the menu (⋮) in the top right corner
3. Select **Repositories**
4. Add: `https://github.com/schmacka/homeassistant-addons`
5. Find "Prusa Connect RTSP Camera" and click **Install**

## Quick Start

1. Get your Prusa Connect token from [connect.prusa3d.com](https://connect.prusa3d.com)
   - Go to your printer's settings
   - Navigate to the "Camera" section
   - Click "Add new other camera" and copy the token

2. Configure your camera in the add-on:
```yaml
cameras:
  - name: "My MK4"
    rtsp_url: "rtsp://192.168.1.100:554/stream"
    token: "your-prusa-connect-token"
    upload_interval: 5
    timelapse_enabled: false
```

3. Start the add-on and check the logs!

## Use Cases

This add-on is perfect if you:
- Own a Prusa 3D printer and use Prusa Connect
- Want to use any RTSP-compatible camera (not just Prusa's official cameras)
- Already run Home Assistant and want centralized camera management
- Have cameras that work with Home Assistant but not directly with Prusa Connect

## Compatible Cameras

Works with any RTSP camera, including:
- Wyze cams (with RTSP firmware)
- Reolink cameras
- Hikvision cameras
- Tapo cameras
- Thingino cameras
- Generic IP cameras with RTSP support

## Credits

This add-on wraps the [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) Python application by Knopersikcuo. All credit for the core streaming functionality goes to them!

## Links

- **GitHub Repository**: https://github.com/schmacka/Prusa-Connect-RTSP-HA
- **Add-on Repository**: https://github.com/schmacka/homeassistant-addons
- **Upstream Project**: https://github.com/Knopersikcuo/Prusa-Connect-RTSP

## Support

If you encounter any issues or have suggestions, please open an issue on the [GitHub repository](https://github.com/schmacka/Prusa-Connect-RTSP-HA/issues).

---

Happy printing! 🖨️
