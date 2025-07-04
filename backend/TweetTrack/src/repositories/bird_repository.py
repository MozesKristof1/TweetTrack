from sqlalchemy.orm import Session, joinedload
from typing import List, Optional, Type
import uuid

from db_tables import UserBird, Bird, BirdLocation


class BirdRepository:
    def __init__(self, db: Session):
        self.db = db

    def fetch_birds(self, limit: int = 100, offset: int = 0):
        return self.db.query(Bird).offset(offset).limit(limit).all()

    def get_bird_by_ebird_id(self, ebird_id: str) -> Optional[Bird]:
        return self.db.query(Bird).filter(Bird.ebird_id == ebird_id).first()

    def get_user_observations(self, skip: int = 0, limit: int = 100, user_id: uuid.UUID = None):
        query = self.db.query(UserBird).options(joinedload(UserBird.bird))

        if user_id:
            query = query.filter(UserBird.user_id == user_id)

        return query.offset(skip).limit(limit).all()
    def create_user_bird_observation(self, user_bird: UserBird) -> UserBird:
        self.db.add(user_bird)
        self.db.commit()
        self.db.refresh(user_bird)

        bird = self.db.query(Bird).filter(Bird.ebird_id == user_bird.ebird_id).first()

        if bird:
            existing_location = self.db.query(BirdLocation).filter(
                BirdLocation.bird_id == bird.id,
                BirdLocation.latitude == user_bird.latitude,
                BirdLocation.longitude == user_bird.longitude
            ).first()

            if not existing_location:
                bird_location = BirdLocation(
                    bird_id=bird.id,
                    latitude=user_bird.latitude,
                    longitude=user_bird.longitude
                )
                self.db.add(bird_location)
                self.db.commit()

        return user_bird

    def get_user_bird_observations(self, skip: int = 0, limit: int = 100) -> list[Type[UserBird]]:
        return (
            self.db.query(UserBird)
            .options(joinedload(UserBird.bird))
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_user_bird_observation_by_id(self, user_bird_id: uuid.UUID, user_id: int) -> Optional[UserBird]:
        return (
            self.db.query(UserBird)
            .options(joinedload(UserBird.bird))
            .filter(
                UserBird.id == user_bird_id,
                UserBird.user_id == user_id
            )
            .first()
        )

    def get_user_bird_by_id_and_user(self, user_bird_id: uuid.UUID, user_id: int) -> Optional[UserBird]:
        return self.db.query(UserBird).filter(
            UserBird.id == user_bird_id,
            UserBird.user_id == user_id
        ).first()

    def get_user_birds_by_ebird_id(self, ebird_id: str) -> list[Type[UserBird]]:
        return self.db.query(UserBird).filter(
            UserBird.ebird_id == ebird_id
        ).all()

    def get_available_birds(self, skip: int = 0, limit: int = 100, search: Optional[str] = None) -> List[Bird]:
        query = self.db.query(Bird)

        if search:
            query = query.filter(
                Bird.name.ilike(f"%{search}%") |
                Bird.scientific_name.ilike(f"%{search}%")
            )

        return query.offset(skip).limit(limit).all()

    def rollback(self):
        self.db.rollback()
