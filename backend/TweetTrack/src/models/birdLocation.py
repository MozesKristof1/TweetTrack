from uuid import UUID
from pydantic import BaseModel

class BirdLocationDTO(BaseModel):
    id: UUID
    birdId: UUID
    latitude: float
    longitude: float