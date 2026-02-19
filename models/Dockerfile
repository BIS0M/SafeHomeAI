# 1. YOLOv8 실행에 최적화된 공식 PyTorch GPU 이미지 사용
FROM ultralytics/ultralytics:latest

# 2. 작업 디렉토리 설정
WORKDIR /app

# 3. 필요한 라이브러리 설치 (GCP 스토리지 연동 등)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. 학습 코드와 설정 파일 복사
COPY . /app

# 5. Vertex AI에서 데이터를 읽어오기 위한 환경 변수 설정 (권장)
ENV PYTHONUNBUFFERED=True

# 6. 학습 실행 명령 (Entrypoint)
ENTRYPOINT ["python", "train.py"]