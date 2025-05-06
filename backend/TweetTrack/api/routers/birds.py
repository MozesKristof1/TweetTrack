from fastapi import APIRouter
from typing import List
from uuid import UUID

from models.bird import Bird

router = APIRouter()

@router.get("/birds", response_model=List[Bird])
async def get_birds():
    birds = [
        Bird(
            id=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            name="American Robin",
            base64Picture="https://cdn.download.ams.birds.cornell.edu/api/v1/asset/303441381/2400",
            description="Fairly large songbird with round body, long legs, and longish tail. Gray above with warm orange underparts and blackish head. Hops across lawns and stands erect with its bill often tilted upward. In fall and winter, forms large flocks and gathers in trees to roost or eat berries. Common across North America in gardens, parks, yards, golf courses, fields, pastures, and many other wooded habitats."
        ),
        Bird(
            id=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd1"),
            name="House Finch",
            base64Picture="https://cdn.download.ams.birds.cornell.edu/api/v1/asset/306327341/2400",
            description="Frequents suburban settings across North America, along with open woods, brushy field edges, and deserts. Males vary in shades and intensity of red. Some males are yellow or orange. Females are drab gray-brown overall with plain faces and blurry streaks on underparts. Similar to Purple and Cassin's Finch, but House Finch males are more orangey-red with color equally bright on crown, throat, and breast. Red color is mostly restricted to head and upper chest, contrasting with cold gray-brown nape, back, and wings. Pale sides show distinct brown streaks, lacking red tones. Females lack bold face pattern and have more diffuse patterning overall. Often sings loudly in neighborhoods and visits feeders."
        ),
        Bird(
            id=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd2"),
            name="Laughing Kookaburra",
            base64Picture="https://cdn.download.ams.birds.cornell.edu/api/v1/asset/121681201/2400",
            description="Frequents suburban settings across North America, along with open woods, brushy field edges, and deserts. Males vary in shades and intensity of red. Some males are yellow or orange. Females are drab gray-brown overall with plain faces and blurry streaks on underparts. Similar to Purple and Cassin's Finch, but House Finch males are more orangey-red with color equally bright on crown, throat, and breast. Red color is mostly restricted to head and upper chest, contrasting with cold gray-brown nape, back, and wings. Pale sides show distinct brown streaks, lacking red tones. Females lack bold face pattern and have more diffuse patterning overall. Often sings loudly in neighborhoods and visits feeders."
        )
    ]
    return birds
