from typing import List
import uuid

from models.birdLocationDTO import BirdLocationDTO
from repositories.bird_location_repository import BirdLocationRepository


class BirdLocationService:
    def __init__(self, location_repo: BirdLocationRepository):
        self.location_repo = location_repo

    def get_all_locations(self, limit: int = 100, offset: int = 0) -> List[BirdLocationDTO]:
        locations = self.location_repo.get_all_locations(limit=limit, offset=offset)
        return [self.to_birdLocationDto(location) for location in locations]

    def get_locations_by_bird_id(self, bird_id: uuid.UUID) -> List[BirdLocationDTO]:
        locations = self.location_repo.get_locations_by_bird_id(bird_id)
        return [self.to_birdLocationDto(location) for location in locations]

    def get_location_by_id(self, location_id: uuid.UUID) -> BirdLocationDTO:
        location = self.location_repo.get_location_by_id(location_id)
        if not location:
            raise ValueError(f"Location with ID {location_id} not found")
        return self.to_birdLocationDto(location)

    def get_locations_in_area(self, min_lat: float, max_lat: float,
                              min_lng: float, max_lng: float) -> List[BirdLocationDTO]:
        locations = self.location_repo.get_locations_in_area(min_lat, max_lat, min_lng, max_lng)
        return [self.to_birdLocationDto(location) for location in locations]

    def to_birdLocationDto(self, location) -> BirdLocationDTO:
        return BirdLocationDTO(
            id=location.id,
            birdId=location.bird_id,
            latitude=location.latitude,
            longitude=location.longitude
        )