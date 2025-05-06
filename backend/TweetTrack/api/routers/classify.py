from fastapi import APIRouter, UploadFile, File
from pydub import AudioSegment
import json
import socket
import asyncio
import tempfile
import os
import io
import librosa
from scipy import signal
import soundfile as sf
import numpy as np


router = APIRouter()

AI_HOST = "model-inference"
AI_PORT = 9000


@router.post("/upload-sound/")
async def upload_sound_file(file: UploadFile = File(...)):
    try:
        audio_bytes = await file.read()
        file_extension = os.path.splitext(file.filename)[1].lower()
        
        supported_formats = {".m4a": "m4a", ".wav": "wav", ".flac": "flac", ".ogg": "ogg",".mp3": "mp3"}
        
        if file_extension in supported_formats:
            with tempfile.NamedTemporaryFile(delete=False, suffix=file_extension) as temp_file:
                temp_file.write(audio_bytes)
                temp_path = temp_file.name
            
            try:
                audio = AudioSegment.from_file(temp_path, format=supported_formats[file_extension])
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

def apply_highpass_filter(mp3_buffer, cutoff_freq=1000, sample_rate=None, order=4):
    y, sr = librosa.load(mp3_buffer, sr=sample_rate, mono=True)
    nyquist = 0.5 * sr
    normalized_cutoff = cutoff_freq / nyquist
    b, a = signal.butter(order, normalized_cutoff, btype='high')
    filtered_audio = signal.filtfilt(b, a, y)
    return filtered_audio, sr


def add_noise(audio_buffer, noise_level=0.005, noise_type='white', sample_rate=None):

    # Load the audio
    y, sr = librosa.load(audio_buffer, sr=sample_rate, mono=True)

    if noise_type == 'white':
        # White noise: equal energy across all frequencies
        noise = np.random.normal(0, noise_level, len(y))

    elif noise_type == 'pink':
        # Pink noise: decreasing energy with increasing frequency (1/f)
        # Generate white noise first
        white_noise = np.random.normal(0, noise_level, len(y))

        # Apply 1/f filter to create pink noise
        # Use FFT to convert to frequency domain
        X = np.fft.rfft(white_noise)
        S = np.arange(1, len(X) + 1)
        S = np.sqrt(1 / S)  # 1/f spectrum
        # Apply filter and inverse FFT
        noise = np.fft.irfft(X * S, len(y))

        # Normalize to have the same energy as specified by noise_level
        noise = noise / np.std(noise) * noise_level

    elif noise_type == 'brown':
        # Brown noise: decreasing energy with increasing frequency (1/f²)
        # Generate white noise first
        white_noise = np.random.normal(0, noise_level, len(y))

        # Apply 1/f² filter
        X = np.fft.rfft(white_noise)
        S = np.arange(1, len(X) + 1)
        S = 1 / S  # 1/f² spectrum (actually 1/f when squared in power)
        # Apply filter and inverse FFT
        noise = np.fft.irfft(X * S, len(y))

        # Normalize
        noise = noise / np.std(noise) * noise_level

    elif noise_type == 'blue':
        # Blue noise: increasing energy with increasing frequency (f)
        white_noise = np.random.normal(0, noise_level, len(y))
        X = np.fft.rfft(white_noise)
        S = np.arange(1, len(X) + 1)
        S = np.sqrt(S) / np.mean(np.sqrt(S))  # f spectrum, normalized
        noise = np.fft.irfft(X * S, len(y))
        noise = noise / np.std(noise) * noise_level

    elif noise_type == 'violet':
        # Violet noise: increasing energy with increasing frequency (f²)
        white_noise = np.random.normal(0, noise_level, len(y))
        X = np.fft.rfft(white_noise)
        S = np.arange(1, len(X) + 1)
        S = S / np.mean(S)  # f² spectrum
        noise = np.fft.irfft(X * S, len(y))
        noise = noise / np.std(noise) * noise_level

    elif noise_type == 'impulse':
        # Impulse noise: random spikes
        noise = np.zeros(len(y))
        # Add random impulses (adjust density as needed)
        impulse_density = 0.01  # Percentage of samples with impulses
        impulse_count = int(len(y) * impulse_density)
        impulse_positions = np.random.choice(len(y), impulse_count, replace=False)
        impulse_values = np.random.uniform(-noise_level * 10, noise_level * 10, impulse_count)
        noise[impulse_positions] = impulse_values

    else:
        raise ValueError(
            f"Unsupported noise type: {noise_type}. Choose from 'white', 'pink', 'brown', 'blue', 'violet', or 'impulse'")

    noisy_audio = y + noise

    noisy_audio = np.clip(noisy_audio, -1.0, 1.0)

    return noisy_audio, sr

@router.post("/test-filter/")
async def test_highpass_filter(
    file: UploadFile = File(...),
    cutoff_freq: int = 1000,
    order: int = 4
):
    try:
        audio_bytes = await file.read()
        file_extension = os.path.splitext(file.filename)[1].lower()
        original_filename = os.path.splitext(file.filename)[0]
        
        if file_extension == ".m4a":
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
        
        # Apply high-pass filter
        filtered_audio, sr = apply_highpass_filter(
            io.BytesIO(audio_bytes), cutoff_freq=cutoff_freq, order=order
        )
        
        # Convert filtered audio back to bytes
        filtered_buffer = io.BytesIO()
        sf.write(filtered_buffer, filtered_audio, sr, format="mp3")
        filtered_buffer.seek(0)
        filtered_bytes = filtered_buffer.read()

        # Save filtered audio to mp3 file
        output_filename = f"{original_filename}_filtered_{cutoff_freq}Hz.mp3"
        output_path = os.path.join("filtered_audio", output_filename)

        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Write filtered audio to file
        with open(output_path, "wb") as f:
            f.write(filtered_bytes)

        print(f"✅ Saved filtered audio to {output_path}")

        data_size = len(filtered_bytes)
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect((AI_HOST, AI_PORT))
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 65536)
        
        print("📡 sending")
        client_socket.sendall(f"{data_size:010}".encode())
        
        await send_data(client_socket, filtered_bytes)
        
        response = client_socket.recv(1024).decode("utf-8")
        client_socket.close()
        
        bird_data = json.loads(response)

        return bird_data
    except Exception as e:
        return {"error": str(e), "detail": "Failed to process audio file"}


@router.post("/test-noise/")
async def test_add_noise(
        file: UploadFile = File(...),
        noise_type: str = "white",
        noise_level: float = 0.005
):
    try:
        audio_bytes = await file.read()
        file_extension = os.path.splitext(file.filename)[1].lower()
        original_filename = os.path.splitext(file.filename)[0]

        # Convert M4A to MP3 if needed
        if file_extension == ".m4a":
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

        # Apply noise to the audio
        noisy_audio, sr = add_noise(
            io.BytesIO(audio_bytes),
            noise_level=noise_level,
            noise_type=noise_type
        )

        # Convert noisy audio back to bytes
        noisy_buffer = io.BytesIO()
        sf.write(noisy_buffer, noisy_audio, sr, format="mp3")
        noisy_buffer.seek(0)
        noisy_bytes = noisy_buffer.read()

        # Save noisy audio to mp3 file
        output_filename = f"{original_filename}_noisy_{noise_type}_{noise_level}.mp3"
        output_path = os.path.join("noisy_audio", output_filename)

        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(output_path), exist_ok=True)

        # Write noisy audio to file
        with open(output_path, "wb") as f:
            f.write(noisy_bytes)

        print(f"✅ Saved noisy audio to {output_path}")

        # Send to AI service
        data_size = len(noisy_bytes)
        client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client_socket.connect((AI_HOST, AI_PORT))
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 65536)
        client_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 65536)

        print("📡 sending")
        client_socket.sendall(f"{data_size:010}".encode())

        await send_data(client_socket, noisy_bytes)

        response = client_socket.recv(1024).decode("utf-8")
        client_socket.close()

        bird_data = json.loads(response)

        return bird_data
    except Exception as e:
        return {"error": str(e), "detail": "Failed to process audio file"}