import os
from dotenv import load_dotenv

base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
load_dotenv(os.path.join(base_dir, ".env"))

class Settings:
    PROJECT_NAME: str = "SafeHomeAI"
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY")
    
    GCP_KEY_PATH = os.path.join(base_dir, "key.json") 
    
    GCS_BUCKET_NAME: str = "safehome-user-assets"
    
    KNOWLEDGE_BASE_PATH: str = os.path.join(
        os.path.dirname(os.path.dirname(__file__)), "data", "safety_knowledge.txt"
    )

    # ✅ 인증(JWT) 설정: 로그인/회원가입 성공 시 토큰 발급에 사용
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "dev-only-secret")
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    JWT_EXPIRE_MINUTES: int = int(os.getenv("JWT_EXPIRE_MINUTES", "60"))

settings = Settings()

