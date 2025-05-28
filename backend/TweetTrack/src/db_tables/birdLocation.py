import uuid
from sqlalchemy import Column, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from . import Base

class BirdLocation(Base):
    __tablename__ = "bird_location"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    bird_id = Column(UUID(as_uuid=True), ForeignKey("bird.id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
