import cv2
import mediapipe as mp
import socket

# Setup UDP Socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
serverAddressPort = ("127.0.0.1", 5050)

# Setup MediaPipe
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(max_num_hands=2, min_detection_confidence=0.7)

cap = cv2.VideoCapture(4)

while True:
    success, img = cap.read()
    if not success:
        break
        
    # Di-flip biar pergerakannya kaya ngaca (mirror), biar gak pusing mainnya
    img = cv2.flip(img, 1) 
    results = hands.process(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))

    if results.multi_hand_landmarks:
        for handLms in results.multi_hand_landmarks:
            # Gambar kerangka tangan agar terlihat di layar
            mp_drawing.draw_landmarks(img, handLms, mp_hands.HAND_CONNECTIONS)
            
            # Ambil landmark nomor 8 (Ujung Jari Telunjuk / Index Finger Tip)
            x = handLms.landmark[8].x
            y = handLms.landmark[8].y
            
            # Kirim data "x,y" lewat UDP
            data = f"{x},{y}"
            sock.sendto(data.encode(), serverAddressPort)

    cv2.imshow("Human Arcade Tracker", img)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()