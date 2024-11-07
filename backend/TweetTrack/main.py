from fastapi import FastAPI
from typing import List
from uuid import UUID

from src.models.bird import Bird
from src.models.birdLocation import BirdLocation

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

@app.get("/location", response_model=List[BirdLocation])
async def get_location():
    locations = [
        BirdLocation(
            id=UUID("cf6a81c1-9f0c-4d72-b37b-56757b5a8b1b"),
            birdId=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            latitude=34.0522,
            longitude=-118.2437
        ),
        BirdLocation(
            id=UUID("71ef4f23-8535-4bbd-8c76-4f7b8f6a087b"),
            birdId=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            latitude=40.7128,
            longitude=-74.0060
        ),
        BirdLocation(
            id=UUID("a73c9832-6af9-4e4a-9a59-320f4b3f1b57"),
            birdId=UUID("df2a3c52-bbe6-4b61-a032-8e3aff5d3dd0"),
            latitude=51.5074,
            longitude=-0.1278
        ),
    ]
    return locations