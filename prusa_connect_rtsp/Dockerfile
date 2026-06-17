ARG BUILD_FROM
FROM $BUILD_FROM

# Install system dependencies and Python packages from Alpine repos
# paho-mqtt comes from the Alpine community repo (avoids a pip build at install time)
RUN apk add --no-cache \
    python3 \
    py3-opencv \
    py3-numpy \
    py3-requests \
    py3-paho-mqtt \
    ffmpeg \
    jq \
    bash

# Copy application files
COPY main.py /
COPY run.sh /

RUN chmod a+x /run.sh

CMD ["/run.sh"]
