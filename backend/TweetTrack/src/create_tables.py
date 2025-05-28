from sqlalchemy import create_engine
from db_tables import Base 

DATABASE_URL = "postgresql://postgres:tweetTrack@postgres:5432/tweettrack_db"

engine = create_engine(DATABASE_URL)

def create_tables():
    # Base.metadata.drop_all(bind=engine)
    try:
        print("Attempting to create tables...")
        Base.metadata.create_all(bind=engine, checkfirst=True)
        print("Tables created successfully (if they didn't already exist).")
    except Exception as e:
        print(f"An error occurred during table creation: {e}")

if __name__ == "__main__":
    create_tables()