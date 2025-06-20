import uuid
from sqlalchemy import Column, String, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from . import Base


class UserBirdImage(Base):
    __tablename__ = "user_bird_image"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_bird_id = Column(UUID(as_uuid=True), ForeignKey("user_bird.id"), nullable=False)
    base64_image = Column(Text)
    caption = Column(String, nullable=True)

    user_bird = relationship("UserBird", back_populates="images")
