import base64
from typing import List, Optional
import uuid
from fastapi import HTTPException, status, UploadFile

from db_tables import UserBird, User, UserBirdImage, UserBirdSound
from models.birdDTO import BirdDTO
from models.observation_helper import BirdObservationResponse, BirdObservationCreate
from repositories.bird_image_repository import BirdImageRepository
from repositories.bird_repository import BirdRepository
from repositories.bird_sound_repository import BirdSoundRepository


class BirdObservationService:
    def __init__(
            self,
            bird_repo: BirdRepository,
            image_repo: BirdImageRepository,
            sound_repo: BirdSoundRepository
    ):
        self.bird_repo = bird_repo
        self.image_repo = image_repo
        self.sound_repo = sound_repo

    def get_all_birds(self, limit=100, offset=0) -> List[BirdDTO]:
        if limit <= 0 or limit > 1000:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Limit must be between 1 and 1000"
            )

        if offset < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Offset must be non-negative"
            )

        birds = self.bird_repo.fetch_birds(limit=limit)

        return [
            BirdDTO(
                id=bird.id,
                ebird_id=bird.ebird_id,
                name=bird.name,
                base_image_url=bird.base_image_url,
                scientific_name=bird.scientific_name,
                description=bird.description,
            )
            for bird in birds
        ]

    def create_bird_observation(
            self,
            observation: BirdObservationCreate,
            current_user: User
    ) -> BirdObservationResponse:
        bird = self.bird_repo.get_bird_by_ebird_id(observation.ebird_id)
        if not bird:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Bird with eBird ID {observation.ebird_id} not found"
            )

        user_bird = UserBird(
            user_id=current_user.id,
            ebird_id=observation.ebird_id,
            latitude=observation.latitude,
            longitude=observation.longitude,
            observed_at=observation.observed_at,
            notes=observation.notes
        )

        try:
            created_observation = self.bird_repo.create_user_bird_observation(user_bird)

            return BirdObservationResponse(
                id=created_observation.id,
                user_id=created_observation.user_id,
                ebird_id=created_observation.ebird_id,
                latitude=created_observation.latitude,
                longitude=created_observation.longitude,
                observed_at=created_observation.observed_at,
                notes=created_observation.notes,
                bird_name=bird.name,
                bird_scientific_name=bird.scientific_name
            )

        except Exception:
            self.bird_repo.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create bird observation"
            )

    def get_user_bird_observations(self, skip: int = 0, limit: int = 100) -> List[BirdObservationResponse]:
        observations = self.bird_repo.get_user_bird_observations(skip, limit)

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

    def get_bird_observation_by_id(
            self,
            user_bird_id: uuid.UUID,
            current_user: User
    ) -> BirdObservationResponse:
        observation = self.bird_repo.get_user_bird_observation_by_id(user_bird_id, current_user.id)

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

    def get_available_birds(
            self,
            skip: int = 0,
            limit: int = 100,
            search: Optional[str] = None
    ) -> List[dict]:
        birds = self.bird_repo.get_available_birds(skip, limit, search)

        return [
            {
                "ebird_id": bird.ebird_id,
                "name": bird.name,
                "scientific_name": bird.scientific_name,
                "description": bird.description
            }
            for bird in birds
        ]


class BirdImageService:
    def __init__(
            self,
            bird_repo: BirdRepository,
            image_repo: BirdImageRepository
    ):
        self.bird_repo = bird_repo
        self.image_repo = image_repo

    def upload_image_for_observation(
            self,
            user_bird_id: uuid.UUID,
            file: UploadFile,
            caption: Optional[str],
            current_user: User
    ) -> dict:
        user_bird = self.bird_repo.get_user_bird_by_id_and_user(user_bird_id, current_user.id)
        if not user_bird:
            raise HTTPException(status_code=404, detail="Observation not found")

        try:
            contents = file.file.read()
            base64_str = base64.b64encode(contents).decode("utf-8")
        finally:
            file.file.close()

        new_image = UserBirdImage(
            user_bird_id=user_bird.id,
            base64_image=base64_str,
            caption=caption
        )

        self.image_repo.create_bird_image(new_image)
        return {"message": "Image uploaded successfully"}

    def list_images_for_bird(self, ebird_id: str) -> dict:
        user_birds = self.bird_repo.get_user_birds_by_ebird_id(ebird_id)
        if not user_birds:
            raise HTTPException(status_code=404, detail="No observations found for this bird")

        user_bird_ids = [user_bird.id for user_bird in user_birds]
        images = self.image_repo.get_images_by_user_bird_ids(user_bird_ids)

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


class BirdSoundService:
    def __init__(
            self,
            bird_repo: BirdRepository,
            sound_repo: BirdSoundRepository
    ):
        self.bird_repo = bird_repo
        self.sound_repo = sound_repo

    def upload_sound_for_observation(
            self,
            user_bird_id: uuid.UUID,
            file: UploadFile,
            identified: bool,
            current_user: User
    ) -> dict:
        allowed_audio_types = [
            "audio/mp3", "audio/wav", "audio/ogg",
            "audio/m4a", "audio/mp4"
        ]

        if file.content_type not in allowed_audio_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid file type. Allowed types: {', '.join(allowed_audio_types)}"
            )

        user_bird = self.bird_repo.get_user_bird_by_id_and_user(user_bird_id, current_user.id)
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

        created_sound = self.sound_repo.create_bird_sound(new_sound)

        return {
            "message": "Sound uploaded successfully",
            "sound_id": str(created_sound.id),
            "file_name": created_sound.file_name,
            "file_type": created_sound.file_type,
            "file_size": created_sound.file_size,
            "identified": created_sound.identified
        }

    def list_sounds_for_observation(
            self,
            user_bird_id: uuid.UUID,
            current_user: User
    ) -> List[dict]:

        user_bird = self.bird_repo.get_user_bird_by_id_and_user(user_bird_id, current_user.id)
        if not user_bird:
            raise HTTPException(status_code=404, detail="Observation not found")

        sounds = self.sound_repo.get_sounds_by_user_bird_id(user_bird_id)

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

    def list_sounds_for_bird(self, ebird_id: str) -> dict:
        user_birds = self.bird_repo.get_user_birds_by_ebird_id(ebird_id)
        if not user_birds:
            raise HTTPException(status_code=404, detail="No observations found for this bird")

        user_bird_ids = [user_bird.id for user_bird in user_birds]
        sounds = self.sound_repo.get_sounds_by_user_bird_ids(user_bird_ids)

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