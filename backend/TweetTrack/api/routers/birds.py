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
            base64Picture="",
            description="A migratory songbird known for its bright orange breast."
        ),
    ]
    return birds
