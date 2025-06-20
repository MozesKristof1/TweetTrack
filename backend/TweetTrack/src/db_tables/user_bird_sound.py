import uuid
from sqlalchemy import Column, String, ForeignKey, Boolean, LargeBinary
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from . import Base

class UserBirdSound(Base):
    __tablename__ = "user_bird_sound"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_bird_id = Column(UUID(as_uuid=True), ForeignKey("user_bird.id"), nullable=False)
    sound_data = Column(LargeBinary, nullable=False)
    file_name = Column(String(255), nullable=True)
    file_type = Column(String(50), nullable=True)
    file_size = Column(String(20), nullable=True)
    identified = Column(Boolean, nullable=False, default=False)

    user_bird = relationship("UserBird", back_populates="sounds")