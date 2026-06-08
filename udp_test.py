import socket

UDP_IP = "127.0.0.1"
UDP_PORT = 5050

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

print(f"Listening on {UDP_IP}:{UDP_PORT}...")
sock.settimeout(2.0)
try:
    data, addr = sock.recvfrom(1024)
    print("Received message:", data.decode())
except socket.timeout:
    print("No data received in 2 seconds.")
