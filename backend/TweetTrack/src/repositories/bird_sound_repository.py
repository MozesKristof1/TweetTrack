from sqlalchemy.orm import Session
from typing import List, Type
import uuid

from db_tables import UserBirdSound


class BirdSoundRepository:
    def __init__(self, db: Session):
        self.db = db

    def create_bird_sound(self, bird_sound: UserBirdSound) -> UserBirdSound:
        self.db.add(bird_sound)
        self.db.commit()
        self.db.refresh(bird_sound)
        return bird_sound

    def get_sounds_by_user_bird_id(self, user_bird_id: uuid.UUID) -> list[Type[UserBirdSound]]:
        return self.db.query(UserBirdSound).filter(
            UserBirdSound.user_bird_id == user_bird_id
        ).all()

    def get_sounds_by_user_bird_ids(self, user_bird_ids: List[uuid.UUID]) -> list[Type[UserBirdSound]]:
        return self.db.query(UserBirdSound).filter(
            UserBirdSound.user_bird_id.in_(user_bird_ids)
        ).all()