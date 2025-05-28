import uuid
from datetime import datetime
from sqlalchemy import Column, ForeignKey, Float, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from . import Base


class UserBird(Base):
    __tablename__ = "user_bird"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("user.id"), nullable=False)
    bird_id = Column(UUID(as_uuid=True), ForeignKey("bird.id"), nullable=False)

    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    observed_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="user_bird_entries")
    bird = relationship("Bird", back_populates="user_bird_entries")

    images = relationship("UserBirdImage", back_populates="user_bird", cascade="all, delete-orphan")
    sounds = relationship("UserBirdSound", back_populates="user_bird", cascade="all, delete-orphan")
