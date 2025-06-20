from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List
import uuid

from db import get_db
from models.birdLocationDTO import BirdLocationDTO
from repositories.bird_location_repository import BirdLocationRepository
from services.bird_location_service import BirdLocationService

router = APIRouter()


def get_bird_location_service(db: Session = Depends(get_db)) -> BirdLocationService:
    location_repo = BirdLocationRepository(db)
    return BirdLocationService(location_repo=location_repo)


@router.get("/location", response_model=List[BirdLocationDTO])
async def get_locations(
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    service: BirdLocationService = Depends(get_bird_location_service)
):
    return service.get_all_locations(limit=limit, offset=offset)


@router.get("/location/bird/{bird_id}", response_model=List[BirdLocationDTO])
async def get_locations_by_bird_id(
    bird_id: uuid.UUID,
    service: BirdLocationService = Depends(get_bird_location_service)
):
    return service.get_locations_by_bird_id(bird_id)


@router.get("/location/{location_id}", response_model=BirdLocationDTO)
async def get_location_by_id(
    location_id: uuid.UUID,
    service: BirdLocationService = Depends(get_bird_location_service)
):
    try:
        return service.get_location_by_id(location_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/location/area", response_model=List[BirdLocationDTO])
async def get_locations_in_area(
    min_lat: float = Query(..., description="Minimum latitude"),
    max_lat: float = Query(..., description="Maximum latitude"),
    min_lng: float = Query(..., description="Minimum longitude"),
    max_lng: float = Query(..., description="Maximum longitude"),
    service: BirdLocationService = Depends(get_bird_location_service)
):
    return service.get_locations_in_area(min_lat, max_lat, min_lng, max_lng)