from fastapi import FastAPI
from typing import List
from uuid import UUID

from src.models.bird import Bird

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/birds", response_model=List[Bird])
async def get_birds():
    birds = [
        Bird(
            id=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            name="American Robin",
            base64Picture="",
            description="A migratory songbird known for its bright orange breast."
        ),
        Bird(
            id=UUID("a83b1f2d-8d41-4f6e-bd7a-fd2d6c5c0e17"),
            name="Blue Jay",
            base64Picture="",
            description="A large, intelligent bird known for its blue coloration and noisy behavior."
        ),
        Bird(
            id=UUID("b47fbb92-f75e-4e1e-a4b5-5d3c0c9f02f1"),
            name="House Sparrow",
            base64Picture="",
            description="A small bird often found in urban areas, recognized by its stout body and short tail."
        ),
    ]
    return birds
