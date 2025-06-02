from sqlalchemy.orm import Session
from db_tables import Bird

def get_birds_db(db: Session, limit: int = 100):
    return db.query(Bird).limit(limit).all()
