from sqlalchemy.orm import Session
from typing import List, Type
import uuid

from db_tables import UserBirdImage


class BirdImageRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_bird_image(self, bird_image: UserBirdImage) -> UserBirdImage:
        self.db.add(bird_image)
        self.db.commit()
        self.db.refresh(bird_image)
        return bird_image

    def get_images_by_user_bird_ids(self, user_bird_ids: List[uuid.UUID]) -> list[Type[UserBirdImage]]:
        return self.db.query(UserBirdImage).filter(
            UserBirdImage.user_bird_id.in_(user_bird_ids)
        ).all()

