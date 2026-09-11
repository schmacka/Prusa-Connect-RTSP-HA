# main.py
import os
import cv2
import requests
import time
import base64
from datetime import datetime
import glob

# Get configuration from ENV or set default values
TOKEN = os.environ.get("TOKEN", "YOUR_TOKEN_HERE")
FINGERPRINT = os.environ.get("FINGERPRINT", "YOUR_FINGERPRINT_HERE")
RTSP_URL = os.environ.get("RTSP_URL")
PRUSA_URL = "https://webcam.connect.prusa3d.com/c/snapshot"

# Upload frequency configuration (in seconds)
UPLOAD_INTERVAL = int(os.environ.get("UPLOAD_INTERVAL", "5"))  # Default 5 seconds

# Timelapse configuration
ENABLE_TIMELAPSE = os.environ.get("ENABLE_TIMELAPSE", "false").lower() == "true"
TIMELAPSE_SAVE_INTERVAL = int(os.environ.get("TIMELAPSE_SAVE_INTERVAL", "30"))  # Save frame every X seconds
TIMELAPSE_DIR = os.environ.get("TIMELAPSE_DIR", "timelapse_frames")
TIMELAPSE_FPS = int(os.environ.get("TIMELAPSE_FPS", "24"))  # FPS for timelapse video

# Check if RTSP_URL is set
if not RTSP_URL:
    print("❌ RTSP_URL is not set. Use: set RTSP_URL=rtsp://your-camera-url")
    exit(1)

# Check fingerprint format and convert if needed
if len(FINGERPRINT) == 40:  # SHA1 hex format
    print(f"🔍 Fingerprint (SHA1 hex): {FINGERPRINT}")
    # Keep as hex string - this might be the correct format
    fingerprint_header = FINGERPRINT
else:
    print(f"🔍 Fingerprint (custom): {FINGERPRINT}")
    fingerprint_header = FINGERPRINT

print(f"📊 Upload interval: {UPLOAD_INTERVAL} seconds")
print("🔄 New HTTP session for each frame (PrusaConnect fix)")
print("📷 New camera connection for each frame (fresh frames fix)")
if ENABLE_TIMELAPSE:
    print(f"🎬 Timelapse enabled: saving every {TIMELAPSE_SAVE_INTERVAL}s, FPS: {TIMELAPSE_FPS}")
    # Create timelapse frames folder
    if not os.path.exists(TIMELAPSE_DIR):
        os.makedirs(TIMELAPSE_DIR)
        print(f"📁 Created folder: {TIMELAPSE_DIR}")

def capture_frame_from_camera():
    """
    Captures a single frame from RTSP camera, opening and closing connection
    
    Returns:
        numpy.ndarray or None: Frame or None on error
    """
    cap = None
    try:
        # Open new camera connection
        cap = cv2.VideoCapture(RTSP_URL)
        if not cap.isOpened():
            print("❌ Cannot open RTSP camera")
            return None
        
        # Set buffer to minimum to get freshest frame
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        
        # Skip first few frames to get the freshest one
        for _ in range(3):
            ret, frame = cap.read()
            if not ret:
                break
        
        # Get final frame
        ret, frame = cap.read()
        if ret:
            return frame
        else:
            print("❌ Cannot capture frame from camera")
            return None
            
    except Exception as e:
        print(f"❌ Error capturing frame: {e}")
        return None
    finally:
        # Always close camera connection
        if cap is not None:
            cap.release()

def send_frame_to_prusa(image_bytes):
    """
    Sends frame to PrusaConnect using new HTTP session for each frame
    
    Args:
        image_bytes: JPEG image bytes
    
    Returns:
        tuple: (success: bool, status_code: int, response_text: str)
    """
    try:
        # Create new session for each frame (PrusaConnect fix)
        session = requests.Session()
        
        # Disable connection pooling to force new connection
        session.mount('https://', requests.adapters.HTTPAdapter(pool_connections=1, pool_maxsize=1))
        
        # CRITICAL: Add Content-Length header!
        content_length = len(image_bytes)
        
        # Prepare headers with Content-Length
        headers = {
            "content-type": "image/jpg",
            "content-length": str(content_length),
            "fingerprint": fingerprint_header,
            "token": TOKEN,
            "connection": "close",  # Force connection close
        }
        
        # Send PUT request with raw image data
        response = session.put(PRUSA_URL, data=image_bytes, headers=headers, timeout=30)
        
        # Explicitly close session
        session.close()
        
        return True, response.status_code, response.text
        
    except Exception as e:
        return False, 0, str(e)

def save_timelapse_frame(frame, frame_count):
    """
    Saves frame to file for timelapse
    
    Args:
        frame: OpenCV frame
        frame_count: Frame number
    """
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"frame_{frame_count:06d}_{timestamp}.jpg"
        filepath = os.path.join(TIMELAPSE_DIR, filename)
        
        # Resize frame for timelapse (optional)
        height, width = frame.shape[:2]
        if width > 1920:  # Reduce if too large
            new_width = 1920
            new_height = int(height * (new_width / width))
            frame = cv2.resize(frame, (new_width, new_height))
        
        cv2.imwrite(filepath, frame)
        return True
    except Exception as e:
        print(f"❌ Error saving timelapse frame: {e}")
        return False

def create_timelapse_video():
    """
    Creates timelapse video from saved frames using OpenCV
    """
    try:
        # Find all JPG files in timelapse folder
        image_files = sorted(glob.glob(os.path.join(TIMELAPSE_DIR, "*.jpg")))
        
        if len(image_files) < 2:
            print(f"⚠️ Not enough frames to create timelapse (found: {len(image_files)})")
            return False
        
        print(f"🎬 Creating timelapse from {len(image_files)} frames...")
        
        # Create timestamp for filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_filename = f"timelapse_{timestamp}.mp4"
        
        # Read first frame to check size
        first_frame = cv2.imread(image_files[0])
        if first_frame is None:
            print("❌ Cannot read first frame")
            return False
        
        height, width, _ = first_frame.shape
        print(f"📏 Frame size: {width}x{height}")
        
        # Configure VideoWriter
        # Try different codecs
        fourcc_options = [
            cv2.VideoWriter_fourcc(*'mp4v'),  # MP4
            cv2.VideoWriter_fourcc(*'XVID'),  # AVI
            cv2.VideoWriter_fourcc(*'MJPG'),  # Motion JPEG
        ]
        
        video_writer = None
        for fourcc in fourcc_options:
            try:
                video_writer = cv2.VideoWriter(output_filename, fourcc, TIMELAPSE_FPS, (width, height))
                if video_writer.isOpened():
                    print(f"✅ Codec configured successfully")
                    break
                else:
                    video_writer.release()
                    video_writer = None
            except:
                continue
        
        if video_writer is None:
            print("❌ Cannot configure VideoWriter")
            return False
        
        # Write frames to video
        print("🎥 Writing frames to video...")
        for i, image_file in enumerate(image_files):
            frame = cv2.imread(image_file)
            if frame is not None:
                # Ensure frame has correct size
                if frame.shape[:2] != (height, width):
                    frame = cv2.resize(frame, (width, height))
                video_writer.write(frame)
                
                # Show progress every 10 frames
                if i % 10 == 0:
                    print(f"   📝 Processed {i+1}/{len(image_files)} frames...")
        
        # Release VideoWriter
        video_writer.release()
        
        # Check if file was created
        if os.path.exists(output_filename):
            file_size = os.path.getsize(output_filename) / 1024 / 1024  # MB
            duration = len(image_files) / TIMELAPSE_FPS
            print(f"✅ Timelapse created: {output_filename}")
            print(f"📊 Duration: {duration:.1f}s at {TIMELAPSE_FPS} FPS")
            print(f"📊 File size: {file_size:.1f} MB")
            return True
        else:
            print("❌ Video file was not created")
            return False
            
    except Exception as e:
        print(f"❌ Error creating timelapse: {e}")
        return False

def cleanup_old_frames(max_frames=1000):
    """
    Removes oldest frames if there are too many
    
    Args:
        max_frames: Maximum number of frames to keep
    """
    try:
        image_files = sorted(glob.glob(os.path.join(TIMELAPSE_DIR, "*.jpg")))
        
        if len(image_files) > max_frames:
            files_to_remove = image_files[:-max_frames]  # Keep only last max_frames
            for file in files_to_remove:
                os.remove(file)
            print(f"🧹 Removed {len(files_to_remove)} old frames")
            
    except Exception as e:
        print(f"❌ Error cleaning up frames: {e}")

# Test camera connection
print("🔌 Testing camera connection...")
test_frame = capture_frame_from_camera()
if test_frame is None:
    print("❌ Cannot connect to RTSP camera.")
    exit(1)

print("✅ Camera connection working. Starting frame upload...")

frame_count = 0
successful_uploads = 0
last_timelapse_save = 0

try:
    while True:
        # Capture fresh frame from camera (new connection)
        frame = capture_frame_from_camera()
        if frame is None:
            print("⚠️ Frame capture error. Waiting...")
            time.sleep(5)
            continue

        current_time = time.time()
        
        # Save frame to timelapse if enabled
        if ENABLE_TIMELAPSE and (current_time - last_timelapse_save) >= TIMELAPSE_SAVE_INTERVAL:
            if save_timelapse_frame(frame, frame_count):
                last_timelapse_save = current_time
                
                # Clean up old frames occasionally
                if frame_count % 100 == 0:
                    cleanup_old_frames()

        # Encode frame to JPEG
        _, jpeg = cv2.imencode('.jpg', frame)
        
        # Convert to bytes (like in JS: Uint8Array.from(binary, (c2) => c2.charCodeAt(0)))
        image_bytes = jpeg.tobytes()
        
        # Send frame using new HTTP session
        success, status_code, response_text = send_frame_to_prusa(image_bytes)
        
        frame_count += 1
        
        if success and status_code == 200:
            successful_uploads += 1
            print(f"📤 Frame #{frame_count} sent successfully. Size: {len(image_bytes)} bytes. Success: {successful_uploads}/{frame_count}")
        elif success and status_code == 429:
            print(f"⚠️ Rate limit exceeded! Increase UPLOAD_INTERVAL (current: {UPLOAD_INTERVAL}s)")
            time.sleep(UPLOAD_INTERVAL * 2)  # Wait longer after rate limit
        else:
            print(f"⚠️ Upload error #{frame_count}: {status_code} - {response_text}")
            # Display error details
            if status_code == 401:
                print("💡 Check if token and fingerprint are correct")
            elif status_code == 400:
                print("💡 Check data format - possible Content-Length issue")
            elif not success:
                print("💡 Connection error - check internet connection")
        
        time.sleep(UPLOAD_INTERVAL)

except KeyboardInterrupt:
    print("\n🛑 Stopped by user")
    
    # Create timelapse on exit if enabled
    if ENABLE_TIMELAPSE:
        print("🎬 Creating final timelapse...")
        create_timelapse_video()
        
finally:
    print("✅ Work completed") 