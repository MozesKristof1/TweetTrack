from contextlib import asynccontextmanager
from fastapi import FastAPI
from routers import birds, locations, classify
from db import engine
from tables import Base

app = FastAPI()

app.include_router(birds.router)
app.include_router(locations.router)
app.include_router(classify.router)