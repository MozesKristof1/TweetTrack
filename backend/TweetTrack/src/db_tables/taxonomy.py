from sqlalchemy import Column, String, ForeignKey, BigInteger
from sqlalchemy.orm import relationship
from . import Base

class Taxonomy(Base):
    __tablename__ = "taxonomy"

    id = Column(BigInteger, ForeignKey("user_bird.id"), primary_key=True)
    scientific_name = Column(String, nullable=False)
    common_name = Column(String, nullable=False)
    genus = Column(String, nullable=False)
    family = Column(String, nullable=False)
    order = Column(String, nullable=False)

    user_bird = relationship("UserBird", back_populates="taxonomy")