from uuid import UUID
from pydantic import BaseModel
from typing_extensions import Optional


class Bird(BaseModel):
    id: UUID
    name: str
    base64Picture: Optional[str] = None
    description: str
