from fastapi import APIRouter, Depends, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid

from db_tables import User
from db import get_db
from auth.auth_utils import get_current_user
from models.observation_helper import BirdObservationResponse, BirdObservationCreate
from repositories.bird_image_repository import BirdImageRepository

from repositories.bird_repository import BirdRepository
from repositories.bird_sound_repository import BirdSoundRepository
from services.observation_service import BirdObservationService, BirdImageService, BirdSoundService

router = APIRouter()


def get_bird_repository(db: Session = Depends(get_db)) -> BirdRepository:
    return BirdRepository(db)

def get_bird_image_repository(db: Session = Depends(get_db)) -> BirdImageRepository:
    return BirdImageRepository(db)

def get_bird_sound_repository(db: Session = Depends(get_db)) -> BirdSoundRepository:
    return BirdSoundRepository(db)

def get_bird_observation_service(
    bird_repo: BirdRepository = Depends(get_bird_repository),
    image_repo: BirdImageRepository = Depends(get_bird_image_repository),
    sound_repo: BirdSoundRepository = Depends(get_bird_sound_repository)
) -> BirdObservationService:
    return BirdObservationService(bird_repo, image_repo, sound_repo)


def get_bird_image_service(
    bird_repo: BirdRepository = Depends(get_bird_repository),
    image_repo: BirdImageRepository = Depends(get_bird_image_repository)
) -> BirdImageService:
    return BirdImageService(bird_repo, image_repo)


def get_bird_sound_service(
    bird_repo: BirdRepository = Depends(get_bird_repository),
    sound_repo: BirdSoundRepository = Depends(get_bird_sound_repository)
) -> BirdSoundService:
    return BirdSoundService(bird_repo, sound_repo)


# Bird Observations
@router.post("/observations", response_model=BirdObservationResponse, status_code=status.HTTP_201_CREATED)
def create_bird_observation(
    observation: BirdObservationCreate,
    current_user: User = Depends(get_current_user),
    service: BirdObservationService = Depends(get_bird_observation_service)
):
    return service.create_bird_observation(observation, current_user)


@router.get("/observations", response_model=List[BirdObservationResponse])
def get_user_bird_observations(
    skip: int = 0,
    limit: int = 100,
    service: BirdObservationService = Depends(get_bird_observation_service)
):
    return service.get_user_bird_observations(skip, limit)

@router.get("/myobservations", response_model=List[BirdObservationResponse])
def get_user_bird_observations(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    service: BirdObservationService = Depends(get_bird_observation_service)
):
    return service.get_user_observations(skip, limit, current_user)



@router.get("/observations/{user_bird_id}", response_model=BirdObservationResponse)
def get_bird_observation(
    user_bird_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: BirdObservationService = Depends(get_bird_observation_service)
):
    return service.get_bird_observation_by_id(user_bird_id, current_user)


# Image Endpoints
@router.post("/observations/{user_bird_id}/images", status_code=201)
def upload_image_for_observation(
    user_bird_id: uuid.UUID,
    file: UploadFile = File(...),
    caption: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    service: BirdImageService = Depends(get_bird_image_service)
):
    return service.upload_image_for_observation(user_bird_id, file, caption, current_user)


@router.get("/images/{ebird_id}")
def list_images_for_bird(
    ebird_id: str,
    service: BirdImageService = Depends(get_bird_image_service)
):
    return service.list_images_for_bird(ebird_id)


# Sound Endpoints
@router.post("/observations/{user_bird_id}/sounds", status_code=201)
def upload_sound_for_observation(
    user_bird_id: uuid.UUID,
    file: UploadFile = File(...),
    identified: bool = Form(default=False),
    current_user: User = Depends(get_current_user),
    service: BirdSoundService = Depends(get_bird_sound_service)
):
    return service.upload_sound_for_observation(user_bird_id, file, identified, current_user)


@router.get("/observations/{user_bird_id}/sounds")
def list_sounds_for_observation(
    user_bird_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    service: BirdSoundService = Depends(get_bird_sound_service)
):
    return service.list_sounds_for_observation(user_bird_id, current_user)


@router.get("/sounds/{ebird_id}")
def list_sounds_for_bird(
    ebird_id: str,
    service: BirdSoundService = Depends(get_bird_sound_service)
):
    return service.list_sounds_for_bird(ebird_id)