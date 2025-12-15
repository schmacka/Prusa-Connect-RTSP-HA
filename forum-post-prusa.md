# Home Assistant Add-on for RTSP Camera Streaming to Prusa Connect

**Recommended Title:** Home Assistant Add-on for Streaming RTSP Cameras to Prusa Connect

**Recommended Category:** Connect / Software (or General Discussion)

---

## Overview

For those who use Home Assistant alongside their Prusa printers, I've created an add-on that makes it simple to stream any RTSP camera to Prusa Connect for remote monitoring.

This is a wrapper around the excellent [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) project by Knopersikcuo, packaged as a native Home Assistant add-on with full UI configuration.

## What is Home Assistant?

Home Assistant is an open-source home automation platform. If you're not familiar with it, think of it as a central hub that can control and monitor smart home devices, cameras, sensors, and more - all from one interface. Many in the 3D printing community use it to monitor printers, control enclosure lighting, manage temperature sensors, etc.

## Why Use This?

**Problem**: You want to monitor your Prusa printer remotely using Prusa Connect, but:
- You don't have a Prusa-branded camera
- You already have an RTSP camera set up
- You want to use existing cameras you have around the house
- You want more flexibility in camera choice

**Solution**: This add-on lets you use ANY RTSP-compatible camera with Prusa Connect!

## Features

- **Wide Camera Compatibility**: Works with Wyze, Reolink, Hikvision, Tapo, Thingino, and any other RTSP camera
- **Multi-Printer Support**: Monitor multiple printers with different cameras
- **Easy Setup**: Configure everything through Home Assistant's UI
- **Timelapse Support**: Automatically capture and generate timelapse videos
- **No Hardware Hacking Required**: Pure software solution

## Installation

If you're already running Home Assistant, installation is simple:

1. Click this button to add the repository:
   [![Add Repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fschmacka%2Fhomeassistant-addons)

2. Install the "Prusa Connect RTSP Camera" add-on

3. Get your Prusa Connect token:
   - Log in to [connect.prusa3d.com](https://connect.prusa3d.com)
   - Go to your printer's settings → Camera section
   - Click "Add new other camera" and copy the token

4. Configure with your camera's RTSP URL and token

5. Start monitoring!

## Configuration Example

```yaml
cameras:
  - name: "MK4 Enclosure Cam"
    rtsp_url: "rtsp://192.168.1.100:554/stream"
    token: "your-prusa-connect-token"
    upload_interval: 5
    timelapse_enabled: true
```

## Real-World Use Case

I use this with a Thingino camera pointed at my MK4. The camera streams over RTSP to Home Assistant, which then forwards frames to Prusa Connect. This gives me:
- Live monitoring through Prusa Connect app
- Timelapse videos of my prints
- Integration with my existing smart home setup
- No need to buy Prusa-specific camera hardware

## Requirements

- Home Assistant installed (on Raspberry Pi, NUC, or any supported hardware)
- RTSP-compatible camera on your network
- Prusa Connect account

## Credits

This add-on wraps the [Prusa-Connect-RTSP](https://github.com/Knopersikcuo/Prusa-Connect-RTSP) Python application by Knopersikcuo. All credit for the core streaming functionality goes to the original author!

## Links

- **GitHub Repository**: https://github.com/schmacka/Prusa-Connect-RTSP-HA
- **Add-on Repository**: https://github.com/schmacka/homeassistant-addons
- **Upstream Project**: https://github.com/Knopersikcuo/Prusa-Connect-RTSP
- **Home Assistant**: https://www.home-assistant.io/

## Questions?

Feel free to ask if you need help getting this set up or have questions about compatibility with your specific camera!

---

Happy printing! 🖨️
