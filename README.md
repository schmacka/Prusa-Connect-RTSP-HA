# Home Assistant Add-on: Prusa Connect RTSP Camera

[![Open your Home Assistant instance and show the add add-on repository dialog](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fschmacka%2FPrusa-Connect-RTSP-HA)

Stream RTSP camera feeds to Prusa Connect for 3D printer monitoring through Home Assistant's configuration UI.

## Features

- **Multi-camera support**: Configure multiple cameras, each with its own Prusa Connect credentials
- **Password-protected tokens**: Prusa Connect tokens are hidden in the UI
- **Timelapse support**: Optional frame capture for timelapse video generation
- **Automated upstream sync**: GitHub Actions workflow keeps the core application updated

## Installation

1. Add this repository to your Home Assistant Add-on Store:
   - Navigate to **Settings** > **Add-ons** > **Add-on Store**
   - Click the menu (three dots) in the top right corner
   - Select **Repositories**
   - Add: `https://github.com/schmacka/Prusa-Connect-RTSP-HA`

2. Find "Prusa Connect RTSP Camera" in the add-on store and click **Install**

3. Configure your cameras in the **Configuration** tab

4. Start the add-on

## Quick Start

1. Get your Prusa Connect token and fingerprint from [connect.prusa3d.com](https://connect.prusa3d.com)
2. Configure your RTSP camera URL
3. Start the add-on and check the logs

See [DOCS.md](DOCS.md) for detailed setup instructions.

## Configuration

```yaml
cameras:
  - name: "My Printer"
    rtsp_url: "rtsp://192.168.1.100:554/stream"
    token: "your-prusa-connect-token"
    fingerprint: "your-40-char-fingerprint"
    upload_interval: 5
    timelapse_enabled: false
```

## Troubleshooting

### Camera images don't appear in Prusa Connect while the printer is off

This is expected. Prusa Connect only accepts and displays webcam snapshots while
the associated printer is **online**. The add-on keeps capturing and uploading
frames regardless, but Prusa's server rejects them until the printer reconnects —
so the snapshot simply stops updating in Connect until the printer is back on.

To avoid flooding the log and hammering Prusa's endpoint during this time, the
add-on automatically backs off: after several consecutive rejected uploads it
progressively increases the interval between attempts (up to 5 minutes), logs a
single "backing off" message, and returns to the normal `upload_interval` with an
"uploads resumed" message as soon as the printer comes back online. No action is
needed — images resume on their own.

## Credits

This add-on wraps [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) by Knopersikcuo.

## License

This project is provided as-is. See the upstream project for license details.
