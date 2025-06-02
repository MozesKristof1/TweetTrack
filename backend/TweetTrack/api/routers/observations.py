import base64

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session, joinedload
from typing import List

from db_tables import UserBird, Bird, User, UserBirdImage, UserBirdSound
from db import get_db
from auth.auth_utils import get_current_user

from typing import Optional
import uuid

from models.observation_helper import BirdObservationResponse, BirdObservationCreate

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


@router.get("/observations/{user_bird_id}", response_model=BirdObservationResponse)
def get_bird_observation(
        user_bird_id: uuid.UUID,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    observation = (
        db.query(UserBird)
        .options(joinedload(UserBird.bird))
        .filter(
            UserBird.id == user_bird_id,
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


@router.post("/observations/{user_bird_id}/images", status_code=201)
def upload_image_for_observation(
        user_bird_id: uuid.UUID,
        file: UploadFile = File,
        caption: Optional[str] = None,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    user_bird = db.query(UserBird).filter(
        UserBird.id == user_bird_id,
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


@router.get("/images/{ebird_id}")
def list_images_for_bird(
        ebird_id: str,
        db: Session = Depends(get_db)
):
    user_birds = db.query(UserBird).filter(
        UserBird.ebird_id == ebird_id
    ).all()

    if not user_birds:
        raise HTTPException(status_code=404, detail="No observations found for this bird")

    user_bird_ids = [user_bird.id for user_bird in user_birds]

    images = db.query(UserBirdImage).filter(
        UserBirdImage.user_bird_id.in_(user_bird_ids)
    ).all()

    result = []
    for image in images:
        user_bird = next(ub for ub in user_birds if ub.id == image.user_bird_id)

        result.append({
            "image_id": str(image.id),
            "observation_id": str(user_bird.id),
            "base64_image": image.base64_image,
            "caption": image.caption,
            "observed_at": user_bird.observed_at.isoformat(),
            "latitude": user_bird.latitude,
            "longitude": user_bird.longitude,
            "notes": user_bird.notes
        })

    return {
        "ebird_id": ebird_id,
        "total_observations": len(user_birds),
        "total_images": len(images),
        "images": result
    }
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


### Sound

@router.post("/observations/{user_bird_id}/sounds", status_code=201)
def upload_sound_for_observation(
        user_bird_id: uuid.UUID,
        file: UploadFile = File(...),
        identified: bool = Form(default=False),
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    allowed_audio_types = [
        "audio/mp3", "audio/wav", "audio/ogg",
        "audio/m4a", "audio/mp4"
    ]

    if file.content_type not in allowed_audio_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed types: {', '.join(allowed_audio_types)}"
        )

    user_bird = db.query(UserBird).filter(
        UserBird.id == user_bird_id,
        UserBird.user_id == current_user.id
    ).first()

    if not user_bird:
        raise HTTPException(status_code=404, detail="Observation not found")

    try:
        contents = file.file.read()

        file_size_str = f"{len(contents)} bytes"

    finally:
        file.file.close()

    new_sound = UserBirdSound(
        user_bird_id=user_bird.id,
        sound_data=contents,
        file_name=file.filename,
        file_type=file.content_type,
        file_size=file_size_str,
        identified=identified
    )

    db.add(new_sound)
    db.commit()
    db.refresh(new_sound)

    return {
        "message": "Sound uploaded successfully",
        "sound_id": str(new_sound.id),
        "file_name": new_sound.file_name,
        "file_type": new_sound.file_type,
        "file_size": new_sound.file_size,
        "identified": new_sound.identified
    }


@router.get("/observations/{user_bird_id}/sounds")
def list_sounds_for_observation(
        user_bird_id: uuid.UUID,
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
):
    user_bird = db.query(UserBird).filter(
        UserBird.id == user_bird_id,
        UserBird.user_id == current_user.id
    ).first()

    if not user_bird:
        raise HTTPException(status_code=404, detail="Observation not found")

    sounds = db.query(UserBirdSound).filter(
        UserBirdSound.user_bird_id == user_bird_id
    ).all()

    return [
        {
            "id": str(sound.id),
            "file_name": sound.file_name,
            "file_type": sound.file_type,
            "file_size": sound.file_size,
            "identified": sound.identified
        }
        for sound in sounds
    ]


@router.get("/sounds/{ebird_id}")
def list_sounds_for_bird(
        ebird_id: str,
        db: Session = Depends(get_db)
):
    # Get all user bird observations for this eBird_id
    user_birds = db.query(UserBird).filter(
        UserBird.ebird_id == ebird_id
    ).all()

    if not user_birds:
        raise HTTPException(status_code=404, detail="No observations found for this bird")

    user_bird_ids = [user_bird.id for user_bird in user_birds]

    sounds = db.query(UserBirdSound).filter(
        UserBirdSound.user_bird_id.in_(user_bird_ids)
    ).all()

    result = []
    for sound in sounds:
        user_bird = next(ub for ub in user_birds if ub.id == sound.user_bird_id)

        sound_data_b64 = base64.b64encode(sound.sound_data).decode('utf-8')

        result.append({
            "sound_id": str(sound.id),
            "observation_id": str(user_bird.id),
            "sound_data_b64": sound_data_b64,
            "file_name": sound.file_name,
            "file_type": sound.file_type,
            "file_size": sound.file_size,
            "identified": sound.identified,
            "observed_at": user_bird.observed_at.isoformat(),
            "latitude": user_bird.latitude,
            "longitude": user_bird.longitude,
            "notes": user_bird.notes
        })

    return {
        "ebird_id": ebird_id,
        "total_observations": len(user_birds),
        "total_sounds": len(sounds),
        "sounds": result
    }