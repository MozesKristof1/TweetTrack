from sqlalchemy.orm import Session
from auth.auth_utils import hash_password, verify_password, create_access_token
from repositories.auth_repository import fetch_user_by_username, create_user


def register_user(db: Session, username: str, email: str, password: str):
    if fetch_user_by_username(db,username):
        return None
    hashed = hash_password(password)
    return create_user(db, username, email, hashed)

def authenticate_user(db: Session, username: str, password: str):
    user = fetch_user_by_username(db, username)
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user

def generate_token(user):
    return create_access_token(data={"sub": user.username})
