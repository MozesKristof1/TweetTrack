import requests
from bs4 import BeautifulSoup

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