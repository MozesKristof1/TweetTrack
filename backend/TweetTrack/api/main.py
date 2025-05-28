from fastapi import FastAPI

from routers import birds, locations, classify, auth


app = FastAPI()

app.include_router(birds.router)
app.include_router(locations.router)
app.include_router(classify.router)
app.include_router(auth.router)
