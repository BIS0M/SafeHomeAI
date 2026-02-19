from datetime import datetime, timedelta, timezone

import jwt
from passlib.context import CryptContext

from app.core.config import settings

_pwd_context = CryptContext(
    schemes=["argon2"],
    deprecated="auto"
)


def hash_password(password: str) -> str:
    """사용자 비밀번호를 argon2로 해시합니다."""
    return _pwd_context.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    """평문 비밀번호와 저장된 해시를 비교합니다."""
    return _pwd_context.verify(password, password_hash)


def create_access_token(subject: str) -> str:
    """로그인/회원가입 성공 시 사용할 JWT(access_token)를 생성합니다."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM
    )

def decode_access_token(token: str) -> dict:
    """
    JWT 토큰을 해독하여 담겨있는 정보(payload)를 반환합니다.
    유효하지 않거나 만료된 토큰일 경우 에러를 발생시킵니다.
    """
    try:
        # settings에 설정된 비밀키와 알고리즘으로 토큰 해독
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET_KEY, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        return payload  # 성공하면 {"sub": "이메일주소", "exp": ...} 반환
    except jwt.PyJWTError:
        # 토큰이 변조되었거나 만료되었을 때 발생하는 모든 에러 처리
        return None