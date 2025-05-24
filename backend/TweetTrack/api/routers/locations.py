from fastapi import APIRouter
from typing import List
from uuid import UUID

from models.birdLocation import BirdLocationDTO

router = APIRouter()

@router.get("/location", response_model=List[BirdLocationDTO])
async def get_location():
    locations = [
        BirdLocationDTO(
            id=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            birdId=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            latitude=34.0522,
            longitude=-118.2437
        ),
    ]
    return locations
