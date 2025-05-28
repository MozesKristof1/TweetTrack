import uuid
from datetime import datetime
from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from . import Base


class UserBirdImage(Base):
    __tablename__ = "user_bird_image"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_bird_id = Column(UUID(as_uuid=True), ForeignKey("user_bird.id"), nullable=False)
    image_url = Column(String, nullable=False)

    uploaded_at = Column(DateTime, default=datetime.utcnow)
    user_bird = relationship("UserBird", back_populates="images")
