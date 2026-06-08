import cv2
import mediapipe as mp
import socket
import math
import threading
import sys
import time

HOST = "127.0.0.1"
PORT = 5050

HEADLESS = "--headless" in sys.argv

mp_hands = mp.solutions.hands
if not HEADLESS:
    mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(max_num_hands=1, model_complexity=0, min_detection_confidence=0.6, min_tracking_confidence=0.6)

cap = cv2.VideoCapture(0)

if not HEADLESS:
    print("Snapmaster Arcade - MediaPipe Hand Tracker (Threaded)")
    print("Open Palm = Move cursor | Fist = Left Click/Hold")
    print("Press 'q' to quit.\n")

# Sensitivity
X_MIN = 0.15
X_MAX = 0.85
Y_MIN = 0.15
Y_MAX = 0.85

def remap(value, in_min, in_max, out_min, out_max):
    mapped = (value - in_min) / (in_max - in_min) * (out_max - out_min) + out_min
    return max(out_min, min(out_max, mapped))

def count_fingers_up(landmarks):
    fingers = 0
    if abs(landmarks[4].x - landmarks[2].x) > 0.05:
        fingers += 1
    finger_tips = [8, 12, 16, 20]
    finger_pips = [6, 10, 14, 18]
    for tip, pip in zip(finger_tips, finger_pips):
        if landmarks[tip].y < landmarks[pip].y:
            fingers += 1
    return fingers

# ============================================================
# SHARED STATE
# ============================================================
lock = threading.Lock()
shared_frame = None
shared_result = None
frame_ready = threading.Event()
running = True

# ============================================================
# THREAD 1: Camera Capture
# ============================================================
def camera_thread():
    global shared_frame, running
    while running:
        success, img = cap.read()
        if not success:
            running = False
            break
        img = cv2.flip(img, 1)
        with lock:
            shared_frame = img.copy()
        frame_ready.set()

# ============================================================
# THREAD 2: AI Processing
# ============================================================
def ai_thread():
    global shared_result, running
    while running:
        frame_ready.wait(timeout=0.1)
        frame_ready.clear()
        
        with lock:
            if shared_frame is None:
                continue
            frame = shared_frame.copy()
        
        small = cv2.resize(frame, (320, 240))
        results = hands.process(cv2.cvtColor(small, cv2.COLOR_BGR2RGB))
        
        aim_x, aim_y, is_fist, fingers = 0.5, 0.5, False, 0
        hand_detected = False
        
        if results.multi_hand_landmarks:
            for handLms in results.multi_hand_landmarks:
                lm = handLms.landmark
                raw_x = lm[9].x
                raw_y = lm[9].y
                aim_x = remap(raw_x, X_MIN, X_MAX, 0.0, 1.0)
                aim_y = remap(raw_y, Y_MIN, Y_MAX, 0.0, 1.0)
                fingers = count_fingers_up(lm)
                is_fist = fingers <= 1
                hand_detected = True
        
        with lock:
            shared_result = {
                "frame": frame if not HEADLESS else None,
                "aim_x": aim_x,
                "aim_y": aim_y,
                "is_fist": is_fist,
                "fingers": fingers,
                "hand_detected": hand_detected,
                "landmarks": results.multi_hand_landmarks if not HEADLESS else None
            }

# ============================================================
# MAIN: Network Send (+ Display if not headless)
# ============================================================
cam_t = threading.Thread(target=camera_thread, daemon=True)
ai_t = threading.Thread(target=ai_thread, daemon=True)
cam_t.start()
ai_t.start()

sock = None
connected = False

while running:
    result = None
    with lock:
        if shared_result is not None:
            result = shared_result.copy()
            if not HEADLESS and shared_result.get("frame") is not None:
                result["frame"] = shared_result["frame"].copy()
    
    if result is None:
        if not HEADLESS:
            if cv2.waitKey(1) & 0xFF == ord('q'):
                running = False
                break
        else:
            time.sleep(0.001)
        continue
    
    hand_detected = result["hand_detected"]
    is_fist = result["is_fist"]
    data_to_send = None
    
    if hand_detected:
        click_val = 1 if is_fist else 0
        data_to_send = f"{result['aim_x']},{result['aim_y']},{click_val}\n"
    
    # Send data
    if data_to_send:
        if not connected:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(0.1)
                sock.connect((HOST, PORT))
                sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                connected = True
            except (ConnectionRefusedError, socket.timeout, OSError):
                sock = None
                connected = False
        
        if connected:
            try:
                sock.sendall(data_to_send.encode())
            except (BrokenPipeError, ConnectionResetError, OSError):
                connected = False
                sock = None

    # Display (only if not headless)
    if not HEADLESS and result.get("frame") is not None:
        img = result["frame"]
        
        if result["landmarks"]:
            for handLms in result["landmarks"]:
                mp_drawing.draw_landmarks(img, handLms, mp_hands.HAND_CONNECTIONS)
        
        if hand_detected:
            h, w, _ = img.shape
            raw_x = remap(result["aim_x"], 0.0, 1.0, X_MIN, X_MAX)
            raw_y = remap(result["aim_y"], 0.0, 1.0, Y_MIN, Y_MAX)
            cx, cy = int(raw_x * w), int(raw_y * h)
            
            if is_fist:
                cv2.circle(img, (cx, cy), 20, (0, 0, 255), cv2.FILLED)
            else:
                cv2.circle(img, (cx, cy), 12, (0, 255, 0), 2)
            
            cv2.rectangle(img, (int(X_MIN * w), int(Y_MIN * h)), (int(X_MAX * w), int(Y_MAX * h)), (100, 100, 100), 1)
        
        status = "CONNECTED" if connected else "WAITING..."
        color = (0, 255, 0) if connected else (0, 0, 255)
        cv2.putText(img, status, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        
        cv2.imshow("Human Arcade Tracker", img)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            running = False
            break

running = False
if sock:
    sock.close()
cap.release()
if not HEADLESS:
    cv2.destroyAllWindows()