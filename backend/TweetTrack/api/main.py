from contextlib import asynccontextmanager
from fastapi import FastAPI
from routers import birds, locations, classify
from db import engine
from tables import Base

@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield
app = FastAPI(lifespan=lifespan)

app.include_router(birds.router)
app.include_router(locations.router)
app.include_router(classify.router)