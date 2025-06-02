from uuid import UUID
from pydantic import BaseModel
from typing_extensions import Optional


class BirdDTO(BaseModel):
    id: UUID
    name: str
    base_image_url: Optional[str] = None
    description: str
