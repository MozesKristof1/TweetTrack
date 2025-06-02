import uuid
from sqlalchemy import Column, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from . import Base

class Bird(Base):
    __tablename__ = "bird"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ebird_id = Column(String, unique=True, nullable=True)
    name = Column(String, unique=True, nullable=False)
    scientific_name = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    base_image_url = Column(String, nullable=True)
    base_sound_url = Column(String, nullable=True)

    user_bird_entries = relationship("UserBird", back_populates="bird")