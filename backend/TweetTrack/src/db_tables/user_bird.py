import uuid
from sqlalchemy import Column, ForeignKey, Float, TIMESTAMP, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from . import Base


class UserBird(Base):
    __tablename__ = "user_bird"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("user.id"), nullable=False)
    ebird_id = Column(String, ForeignKey("bird.ebird_id"), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    observed_at = Column(TIMESTAMP(timezone=True), nullable=False)
    notes = Column(String, nullable=True)

    user = relationship("User", back_populates="user_bird_entries")
    bird = relationship("Bird", back_populates="user_bird_entries")
    images = relationship("UserBirdImage", back_populates="user_bird", cascade="all, delete-orphan")
    sounds = relationship("UserBirdSound", back_populates="user_bird", cascade="all, delete-orphan")
    taxonomy = relationship("Taxonomy", uselist=False, back_populates="user_bird")
