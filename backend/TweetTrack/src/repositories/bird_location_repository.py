from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
from db_tables import BirdLocation


class BirdLocationRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_all_locations(self, limit: int = 100, offset: int = 0) -> List[BirdLocation]:
        return self.db.query(BirdLocation).offset(offset).limit(limit).all()

    def get_locations_by_bird_id(self, bird_id: uuid.UUID) -> List[BirdLocation]:
        return self.db.query(BirdLocation).filter(BirdLocation.bird_id == bird_id).all()

    def get_location_by_id(self, location_id: uuid.UUID) -> Optional[BirdLocation]:
        return self.db.query(BirdLocation).filter(BirdLocation.id == location_id).first()

    def create_location(self, bird_location: BirdLocation) -> BirdLocation:
        self.db.add(bird_location)
        self.db.commit()
        self.db.refresh(bird_location)
        return bird_location

    def get_locations_in_area(self, min_lat: float, max_lat: float,
                              min_lng: float, max_lng: float) -> List[BirdLocation]:
        return self.db.query(BirdLocation).filter(
            BirdLocation.latitude >= min_lat,
            BirdLocation.latitude <= max_lat,
            BirdLocation.longitude >= min_lng,
            BirdLocation.longitude <= max_lng
        ).all()

    def rollback(self):
        self.db.rollback()