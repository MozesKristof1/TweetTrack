import socket
from fastapi import APIRouter, UploadFile, File
import asyncio

router = APIRouter()

AI_HOST = "model-inference" 
AI_PORT = 9000

@router.post("/upload-sound/")
async def upload_sound_file(file: UploadFile = File(...)):
     
    audio_bytes = await file.read()
    data_size = len(audio_bytes)
    
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((AI_HOST, AI_PORT))

    client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
    client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 65536)

    print("📡 sending")

    # send audio file size
    client_socket.sendall(f"{data_size:010}".encode())

    # send audio in bytes
    await send_data(client_socket, audio_bytes)

    response = client_socket.recv(1024).decode()
    client_socket.close()

    bird_name = response

    return {"bird and probability": bird_name}

async def send_data(client_socket, data):
    loop = asyncio.get_running_loop()
    await loop.sock_sendall(client_socket, data)