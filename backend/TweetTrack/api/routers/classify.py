import socket
from fastapi import APIRouter, UploadFile, File

router = APIRouter()

AI_HOST = "model-inference" 
AI_PORT = 9000

@router.post("/upload-sound/")
async def upload_sound_file(file: UploadFile = File(...)):
    

    audio_bytes = await file.read()
    data_size = len(audio_bytes)
    
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((AI_HOST, AI_PORT))
    print("📡 sending")

    # send audio file size
    client_socket.sendall(f"{data_size:010}".encode())

    # send audio in bytes
    client_socket.sendall(audio_bytes)

    response = client_socket.recv(1024).decode()
    client_socket.close()

    bird_name, confidence = response.split("|")

    return {"bird": bird_name, "confidence": float(confidence)}