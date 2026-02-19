from fastapi import FastAPI
from app.api import endpoints
from fastapi.middleware.cors import CORSMiddleware  
app = FastAPI(title="SafeHomeAI Backend", version="2.0")

# 크롬 브라우저에서 오는 신호를 허락해주는 설정 추가
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(endpoints.router, prefix="/api")

@app.get("/")
async def root():
    return {"status": "online", "message": "SafeHomeAI API is running with Layered Architecture"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)