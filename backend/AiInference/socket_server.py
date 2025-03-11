import json
import socket
from io import BytesIO
from pydub import AudioSegment
from web_scraping.ebird_scraper import scrape_ebird_species
from identifier import classify_bird

HOST = "0.0.0.0"    
PORT = 9000

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((HOST, PORT))
    server_socket.listen(5)

    print(f"🎙 AI Service listening on {HOST}:{PORT}")

    while True:
        client_socket, addr = server_socket.accept()
        print(f"🔗 Connection from {addr}")

        data_size_bytes = client_socket.recv(10)
        if not data_size_bytes:
            print("No size received!")
            client_socket.close()
            continue

        data_size = int(data_size_bytes.decode().strip())
        print(f"Expecting {data_size} bytes")

        audio_data = b""
        while len(audio_data) < data_size:
            chunk = client_socket.recv(data_size)
            if not chunk:
                break
            audio_data += chunk
            print(f"📦 Received {len(chunk)} bytes (Total: {len(audio_data)}/{data_size})")

        print(f"Finished receiving {len(audio_data)} bytes")

        if len(audio_data) == data_size:
            print("✅ Data fully received!")
        else:
            print(f"Data incomplete! Received {len(audio_data)} bytes out of {data_size}")

        result = classify_bird(convert_bytes_to_MP3(audio_data))

        scraped_bird = scrape_ebird_species(result[0])
        print(scraped_bird)

        scraped_bird_json = json.dumps(scraped_bird)

        # Send identified bird back
        client_socket.sendall(scraped_bird_json.encode('utf-8'))
        client_socket.close()

def convert_bytes_to_MP3(audio_data):
    audio_file = BytesIO(audio_data)

    audio = AudioSegment.from_mp3(audio_file)

    output = BytesIO()
    audio.export(output, format="mp3")
    output.seek(0)

    # Return MP3 data
    return output.read()

start_server()
