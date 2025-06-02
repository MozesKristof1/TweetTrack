from fastapi import FastAPI

from routers import birds, locations, classify, auth, observations


app = FastAPI()

app.include_router(birds.router)
app.include_router(locations.router)
app.include_router(classify.router)
app.include_router(auth.router)
app.include_router(observations.router)
