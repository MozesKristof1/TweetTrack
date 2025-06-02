from fastapi import APIRouter, Depends
from typing import List
from sqlalchemy.orm import Session

from db import get_db
from models.birdDTO import BirdDTO
from db_tables import Bird

router = APIRouter()


@router.get("/birds", response_model=List[BirdDTO])
def get_birds(limit: int = 100, db: Session = Depends(get_db)):
    birds = db.query(Bird).limit(limit).all()
    return birds

