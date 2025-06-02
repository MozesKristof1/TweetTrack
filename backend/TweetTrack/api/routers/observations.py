import base64

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session, joinedload
from typing import List

from db_tables import UserBird, Bird, User, UserBirdImage
from db import get_db
from auth.auth_utils import get_current_user

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
import uuid


class BirdObservationCreate(BaseModel):
    ebird_id: str = Field(...)
    latitude: float = Field(..., ge=-90, le=90, )
    longitude: float = Field(..., ge=-180, le=180, )
    observed_at: datetime = Field(...)
    notes: Optional[str] = Field(None, max_length=1000)


class BirdObservationResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    ebird_id: str
    latitude: float
    longitude: float
    observed_at: datetime
    notes: Optional[str]
    bird_name: Optional[str] = None
    bird_scientific_name: Optional[str] = None

    class Config:
        from_attributes = True


router = APIRouter()


@router.post("/observations", response_model=BirdObservationResponse, status_code=status.HTTP_201_CREATED)
def create_bird_observation(
        observation: BirdObservationCreate,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    bird = db.query(Bird).filter(Bird.ebird_id == observation.ebird_id).first()
    if not bird:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Bird with eBird ID {observation.ebird_id} not found"
        )

    # Create the observation
    user_bird = UserBird(
        user_id=current_user.id,
        ebird_id=observation.ebird_id,
        latitude=observation.latitude,
        longitude=observation.longitude,
        observed_at=observation.observed_at,
        notes=observation.notes
    )

    try:
        db.add(user_bird)
        db.commit()
        db.refresh(user_bird)

        # Return response with bird details
        return BirdObservationResponse(
            id=user_bird.id,
            user_id=user_bird.user_id,
            ebird_id=user_bird.ebird_id,
            latitude=user_bird.latitude,
            longitude=user_bird.longitude,
            observed_at=user_bird.observed_at,
            notes=user_bird.notes,
            bird_name=bird.name,
            bird_scientific_name=bird.scientific_name
        )

    except Exception:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create bird observation"
        )


@router.get("/observations", response_model=List[BirdObservationResponse])
def get_user_bird_observations(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db),
        skip: int = 0,
        limit: int = 100
):
    observations = (
        db.query(UserBird)
        .options(joinedload(UserBird.bird))
        .filter(UserBird.user_id == current_user.id)
        .offset(skip)
        .limit(limit)
        .all()
    )

    return [
        BirdObservationResponse(
            id=obs.id,
            user_id=obs.user_id,
            ebird_id=obs.ebird_id,
            latitude=obs.latitude,
            longitude=obs.longitude,
            observed_at=obs.observed_at,
            notes=obs.notes,
            bird_name=obs.bird.name if obs.bird else None,
            bird_scientific_name=obs.bird.scientific_name if obs.bird else None
        )
        for obs in observations
    ]


@router.get("/observations/{observation_id}", response_model=BirdObservationResponse)
def get_bird_observation(
        observation_id: uuid.UUID,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    observation = (
        db.query(UserBird)
        .options(joinedload(UserBird.bird))
        .filter(
            UserBird.id == observation_id,
            UserBird.user_id == current_user.id
        )
        .first()
    )

    if not observation:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bird observation not found"
        )

    return BirdObservationResponse(
        id=observation.id,
        user_id=observation.user_id,
        ebird_id=observation.ebird_id,
        latitude=observation.latitude,
        longitude=observation.longitude,
        observed_at=observation.observed_at,
        notes=observation.notes,
        bird_name=observation.bird.name if observation.bird else None,
        bird_scientific_name=observation.bird.scientific_name if observation.bird else None
    )

@router.post("/observations/{observation_id}/images", status_code=201)
def upload_image_for_observation(
    observation_id: uuid.UUID,
    file: UploadFile = File,
    caption: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_bird = db.query(UserBird).filter(
        UserBird.id == observation_id,
        UserBird.user_id == current_user.id
    ).first()

    if not user_bird:
        raise HTTPException(status_code=404, detail="Observation not found")

    try:
        contents = file.file.read()
        # Store image in binary
    finally:
        file.file.close()

    new_image = UserBirdImage(
        user_bird_id=user_bird.id,
        base64_image=contents,
        caption=caption
    )
    db.add(new_image)
    db.commit()

    return {"message": "Image uploaded successfully"}

@router.get("/available", response_model=List[dict])
def get_available_birds(
        db: Session = Depends(get_db),
        skip: int = 0,
        limit: int = 100,
        search: str = None
):
    query = db.query(Bird)

    if search:
        query = query.filter(
            Bird.name.ilike(f"%{search}%") |
            Bird.scientific_name.ilike(f"%{search}%")
        )

    birds = query.offset(skip).limit(limit).all()

    return [
        {
            "ebird_id": bird.ebird_id,
            "name": bird.name,
            "scientific_name": bird.scientific_name,
            "description": bird.description
        }
        for bird in birds
    ]
