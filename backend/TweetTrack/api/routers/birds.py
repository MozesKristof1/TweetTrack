from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from db import get_db
from models.birdDTO import BirdDTO
from services.bird_service import BirdService
from repositories.bird_repository import BirdRepository

router = APIRouter()


def get_bird_service(db: Session = Depends(get_db)) -> BirdService:
    bird_repo = BirdRepository(db)

    return BirdService(
        bird_repo=bird_repo,
    )


@router.get("/birds", response_model=List[BirdDTO])
def get_birds(
        limit: int = 100,
        service: BirdService = Depends(get_bird_service)
):
    return service.get_all_birds(limit=limit, offset=0)