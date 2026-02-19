# 1. GPU 지원 파이토치 베이스 이미지
FROM pytorch/pytorch:2.1.0-cuda11.8-cudnn8-runtime

# 2. 시스템 패키지 설치 (+ curl, gnupg, gcloud-cli 설치)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# [핵심] gcloud storage 명령어를 사용하기 위한 Google Cloud SDK 설치
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-cli

WORKDIR /app

# 3. 라이브러리 설치
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 4. 학습 코드 복사
COPY train.py .

# 5. 실행
ENTRYPOINT ["python", "-u", "train.py"]