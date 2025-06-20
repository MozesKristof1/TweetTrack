🐦 TweetTrack

TweetTrack is a modern birdwatching application that empowers hobbyists and professionals alike to identify, log, and share bird sightings using AI-powered sound recognition. Combining a user-friendly mobile interface with robust backend services.

🌟 Features

🎙️ Bird Identification via recorded bird sounds using a deep learning model (Perch)

📍 Location-tagged Observations: Automatically link bird sightings with geographic coordinates

🖼️ Image Upload: Attach photos to bird observations

📊 Bird Species Database: Access a growing list of recognized bird species

👥 Community Sharing: Post your findings and explore others’ observations

⚙️ RESTful API: Clean architecture using FastAPI, service and repository layers

📱 Native iOS App for seamless mobile experience

Frontend: Swift (iOS)

Backend: FastAPI (Python), SQLAlchemy

Database: PostgreSQL

AI Model: Perch – audio-based bird species classifier made by Google

Infrastructure: Docker

Authentication: JWT-based (if applicable)



🚀 Getting Started

🔨Requirements
Docker & Docker Compose

Python 3.10+

PostgreSQL

Swift/iOS development environment (Xcode)

Backend Setup

git clone 

cd TweetTrack/backend

docker-compose up --build

The FastAPI will be available at http://localhost:8000.
The endpoinds can be seen at: 
  -> Swagger: http://localhost:8000/docs
  -> ReDoc: http://localhost:8000/redoc


Mobile Setup 

Open the iOS project in Xcode from the /mobile/swift/TweetTrack directory.

Configure the backend URL in the constants file.

Build and run on a simulator or real device.
