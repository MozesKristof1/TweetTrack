import socket
from io import BytesIO
import requests
from pydub import AudioSegment
from bs4 import BeautifulSoup


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
            chunk = client_socket.recv(min(4096, data_size - len(audio_data)))
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

        # Send identified bird back
        client_socket.sendall(scraped_bird['common_name'].encode())
        client_socket.close()


def convert_bytes_to_MP3(audio_data):
    audio_file = BytesIO(audio_data)

    audio = AudioSegment.from_mp3(audio_file)

    output = BytesIO()
    audio.export(output, format="mp3")
    output.seek(0)

    # Return MP3 data
    return output.read()


def scrape_ebird_species(ebird_species_id):
    url = f"https://ebird.org/species/{ebird_species_id}"
    headers = {'User-Agent': 'Mozilla/5.0'}
    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        return f"Error, Status Code: {response.status_code})"

    soup = BeautifulSoup(response.text, 'html.parser')

    # Extract common name and scientific name
    species_header = soup.find('h1', {'id': 'content'})
    if species_header:
        common_name = species_header.find('span', class_='Heading-main').text.strip()
        scientific_name = species_header.find('span', class_='Heading-sub').text.strip()
    else:
        common_name = scientific_name = 'Not found'

    # Extract bird description
    identification_section = soup.find('div', class_='Species-identification-text')
    if identification_section and identification_section.p:
        identification_text = identification_section.p.text.strip()
    else:
        identification_text = 'Not found'

    # Extract image URL
    image_button = soup.find('button', class_='Species-media-button')
    if image_button and image_button.img:
        image_url = image_button.img['src']
    else:
        image_url = 'Not found'

    return {
        'common_name': common_name,
        'scientific_name': scientific_name,
        'identification_text': identification_text,
        'image_url': image_url
    }

start_server()
