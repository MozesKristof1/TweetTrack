import uuid
from sqlalchemy import Column, String, Text
from sqlalchemy.dialects.postgresql import UUID
from . import Base

class Bird(Base):
    __tablename__ = "bird"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    base64Picture = Column(Text, nullable=True)
    description = Column(Text, nullable=False)
