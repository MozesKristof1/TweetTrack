from typing import Optional

import uuid
from pydantic import BaseModel, Field
from datetime import datetime


class BirdObservationCreate(BaseModel):
    ebird_id: str = Field(...)
    latitude: float = Field(..., ge=-90, le=90, )
    longitude: float = Field(..., ge=-180, le=180, )
    observed_at: datetime = Field(...)
    notes: Optional[str] = Field(None, max_length=1000)


class BirdObservationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    ebird_id: str
    latitude: float
    longitude: float
    observed_at: datetime
    notes: Optional[str]
    bird_name: Optional[str] = None
    bird_scientific_name: Optional[str] = None

    class Config:
        from_attributes = True
