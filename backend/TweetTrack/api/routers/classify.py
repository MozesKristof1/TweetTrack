from fastapi import APIRouter, UploadFile, File
from pydub import AudioSegment
import json
import socket
import asyncio
import tempfile
import os
import io

router = APIRouter()

AI_HOST = "model-inference"
AI_PORT = 9000


@router.post("/upload-sound/")
async def upload_sound_file(file: UploadFile = File(...)):
    try:
        audio_bytes = await file.read()

        if file.filename.lower().endswith('.m4a'):

            with tempfile.NamedTemporaryFile(delete=False, suffix=".m4a") as temp_file:
                temp_file.write(audio_bytes)
                temp_path = temp_file.name

            try:
                audio = AudioSegment.from_file(temp_path, format="m4a")

                mp3_buffer = io.BytesIO()
                audio.export(mp3_buffer, format="mp3")
                mp3_buffer.seek(0)

                audio_bytes = mp3_buffer.read()

            except Exception as e:
                print(f"❌ Conversion error: {str(e)}")
                raise
            finally:
                if os.path.exists(temp_path):
                    os.remove(temp_path)

        data_size = len(audio_bytes)

        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect((AI_HOST, AI_PORT))

        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 65536)

        print("📡 sending")

        client_socket.sendall(f"{data_size:010}".encode())

        await send_data(client_socket, audio_bytes)

        response = client_socket.recv(1024).decode("utf-8")
        client_socket.close()

        bird_data = json.loads(response)

        return bird_data

    except Exception as e:
        return {"error": str(e), "detail": "Failed to process audio file"}

async def send_data(client_socket, data):
    loop = asyncio.get_running_loop()
    await loop.sock_sendall(client_socket, data)
