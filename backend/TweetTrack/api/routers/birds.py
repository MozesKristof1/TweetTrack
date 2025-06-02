from fastapi import APIRouter, Depends
from typing import List
from sqlalchemy.orm import Session

from db import get_db
from models.birdDTO import BirdDTO
from backend.TweetTrack.api.services.bird_service import get_birds as get_birds_service

router = APIRouter()


@router.get("/birds", response_model=List[BirdDTO])
def get_birds(limit: int = 100, db: Session = Depends(get_db)):
    birds = get_birds_service(db, limit)
    return birds

