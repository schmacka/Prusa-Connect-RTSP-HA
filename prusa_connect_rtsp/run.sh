#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json
FINGERPRINT_DIR=/data/fingerprints
PIDS=()

# Create fingerprint storage directory
mkdir -p "$FINGERPRINT_DIR"

# Test Python and dependencies
bashio::log.info "Testing Python environment..."
if ! python3 -c "import cv2; import requests; print('Dependencies OK')" 2>&1; then
    bashio::log.error "Python dependencies failed to load!"
    bashio::log.error "Try rebuilding the addon."
    exit 1
fi
bashio::log.info "Python environment ready"

# Detect MQTT broker from Home Assistant services
if bashio::services.available "mqtt"; then
    MQTT_HOST=$(bashio::services mqtt "host")
    MQTT_PORT=$(bashio::services mqtt "port")
    MQTT_USER=$(bashio::services mqtt "username")
    MQTT_PASS=$(bashio::services mqtt "password")
    bashio::log.info "MQTT broker found at ${MQTT_HOST}:${MQTT_PORT}"
    export MQTT_HOST MQTT_PORT MQTT_USER MQTT_PASS
else
    bashio::log.warning "MQTT broker not available - camera entities will not be created in Home Assistant"
    bashio::log.warning "Install Mosquitto broker addon for HA camera entity support"
fi

# Get number of cameras
CAMERAS_COUNT=$(jq '.cameras | length' $CONFIG_PATH)
bashio::log.info "Found ${CAMERAS_COUNT} camera(s) configured"

# Iterate over each camera
for (( i=0; i<CAMERAS_COUNT; i++ )); do
    CAMERA_NAME=$(jq -r ".cameras[$i].name" $CONFIG_PATH)
    CAMERA_SLUG="${CAMERA_NAME// /_}"

    # Get fingerprint from config, or auto-generate if empty
    FINGERPRINT=$(jq -r ".cameras[$i].fingerprint // empty" $CONFIG_PATH)
    if [ -z "$FINGERPRINT" ]; then
        FINGERPRINT_FILE="$FINGERPRINT_DIR/${CAMERA_SLUG}.txt"
        if [ -f "$FINGERPRINT_FILE" ]; then
            FINGERPRINT=$(cat "$FINGERPRINT_FILE")
            bashio::log.info "Using stored fingerprint for ${CAMERA_NAME}"
        else
            # Generate 40-char hex fingerprint (like SHA1 format)
            FINGERPRINT=$(cat /proc/sys/kernel/random/uuid | tr -d '-')$(cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 8)
            echo "$FINGERPRINT" > "$FINGERPRINT_FILE"
            bashio::log.info "Generated new fingerprint for ${CAMERA_NAME}: ${FINGERPRINT}"
        fi
    fi

    # Export environment variables for Python script
    export CAMERA_NAME="$CAMERA_NAME"
    export CAMERA_SLUG="$CAMERA_SLUG"
    export RTSP_URL=$(jq -r ".cameras[$i].rtsp_url" $CONFIG_PATH)
    export TOKEN=$(jq -r ".cameras[$i].token" $CONFIG_PATH)
    export FINGERPRINT
    export UPLOAD_INTERVAL=$(jq -r ".cameras[$i].upload_interval" $CONFIG_PATH)
    export ENABLE_TIMELAPSE=$(jq -r ".cameras[$i].timelapse_enabled" $CONFIG_PATH)
    export TIMELAPSE_SAVE_INTERVAL=$(jq -r ".cameras[$i].timelapse_save_interval // 30" $CONFIG_PATH)
    export TIMELAPSE_FPS=$(jq -r ".cameras[$i].timelapse_fps // 24" $CONFIG_PATH)
    export TIMELAPSE_DIR="/share/prusa_connect_rtsp/${CAMERA_SLUG}"

    mkdir -p "$TIMELAPSE_DIR"

    # Mask any credentials embedded in the RTSP URL before logging it.
    # Host/port/path stay visible so connection problems remain diagnosable.
    RTSP_URL_SAFE=$(echo "$RTSP_URL" | sed 's|://[^/@]*@|://***:***@|')

    # Log configuration details
    bashio::log.info "-------------------------------------------"
    bashio::log.info "Camera ${i}: ${CAMERA_NAME}"
    bashio::log.info "  RTSP URL: ${RTSP_URL_SAFE}"
    bashio::log.info "  Fingerprint: ${FINGERPRINT}"
    bashio::log.info "  Token: ${TOKEN:0:8}... (hidden)"
    bashio::log.info "  Upload interval: ${UPLOAD_INTERVAL}s"
    bashio::log.info "  Timelapse: ${ENABLE_TIMELAPSE}"
    bashio::log.info "-------------------------------------------"

    bashio::log.info "Starting camera: ${CAMERA_NAME}"
    # Use unbuffered Python output (-u) for real-time logging
    python3 -u /main.py 2>&1 | while IFS= read -r line; do
        bashio::log.info "[${CAMERA_NAME}] ${line}"
    done &
    PIDS+=($!)
done

# Wait for all processes
wait "${PIDS[@]}"
