from http.client import HTTPException
from typing import Optional

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from jose import jwt
from datetime import datetime, timedelta

from requests import Session

from db import get_db
from db_tables import User

SECRET_KEY = "D9wWbM2m_ZVGo9oLgR8_xsMcT3lp0hqDk4NLqKwMfhYtO0xh2pK7s1z7q2Vvp8Dk"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 1000000000
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException()
    except:
        raise HTTPException()

    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise HTTPException(detail="User not found")
    return user