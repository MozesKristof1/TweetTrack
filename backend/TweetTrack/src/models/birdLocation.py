from uuid import UUID
from pydantic import BaseModel

class BirdLocation(BaseModel):
    id: UUID
    birdId: UUID
    latitude: float
    longitude: float