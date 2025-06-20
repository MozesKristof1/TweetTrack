from typing import List
from fastapi import HTTPException, status

from models.birdDTO import BirdDTO
from repositories.bird_repository import BirdRepository


class BirdService:
    def __init__(
            self,
            bird_repo: BirdRepository,
    ):
        self.bird_repo = bird_repo

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
