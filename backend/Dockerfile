# 1. Python 3.13 슬림 이미지 사용
FROM python:3.13-slim

# 로그가 버퍼링 없이 즉시 출력되도록 설정
ENV PYTHONUNBUFFERED=1

# 2. 시스템 의존성 설치 (OpenCV 등 비전 라이브러리용)
RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 3. 라이브러리 설치
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 4. 소스 코드 복사
COPY . .

# 5. 실행 (포트 자동 할당 대응)
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}