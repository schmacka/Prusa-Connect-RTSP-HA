ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

# Install system dependencies and Python packages from Alpine repos
RUN apk add --no-cache \
    python3 \
    py3-opencv \
    py3-numpy \
    py3-requests \
    py3-paho-mqtt \
    ffmpeg \
    jq \
    bash

# Install paho-mqtt for Home Assistant MQTT camera discovery
#RUN pip3 install --no-cache-dir --break-system-packages paho-mqtt

# Copy application files
COPY main.py /
COPY run.sh /

RUN chmod a+x /run.sh

CMD ["/run.sh"]
