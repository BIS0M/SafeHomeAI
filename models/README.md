1. data.yaml 작성 (30개 클래스 기준)
사용자님께서 나열해주신 표를 바탕으로 YOLOv8 표준 형식에 맞춰 작성했습니다. 클래스 개수는 총 30개로 확인되었습니다. (추후 데이터셋 상황에 따라 nc와 names를 조정하시면 됩니다.)

2. Dockerfile 작성 (GCP 전송용 포장지)
Vertex AI에서 학습을 실행하기 위해 필요한 모든 환경(Python, YOLO 라이브러리, GPU 드라이버 통신 등)을 하나로 묶는 설계도입니다.

3. train.py 상세 설명 및 궁금증 해결
제시해 드린 train.py는 '학습 실행기' 역할을 합니다. 사용자님의 질문에 하나씩 답해 드릴게요.

> Q1. val과 test는 왜 코드에 없나요?
YOLOv8의 핵심 철학은 **"설정은 data.yaml에서, 실행은 코드에서"**입니다.

Validation (val): model.train() 함수가 실행될 때, YOLO는 자동으로 data.yaml에 적힌 val 경로를 찾아가서 매 epoch마다 검증을 수행합니다. 즉, 코드에 명시하지 않아도 이미 포함되어 작동 중입니다.

Test: 보통 학습 중에는 사용하지 않고, 학습이 완전히 끝난 모델(best.pt)의 최종 성능을 평가할 때 별도로 돌립니다. 필요하다면 model.val(data='data.yaml', split='test') 한 줄로 나중에 추가할 수 있습니다.

> Q2. train.py 코드 심층 분석

```bash
model.train(
    data=args.data_yaml_path, # data.yaml 위치 (어떤 물체를 학습할지)
    epochs=args.epochs,       # 전체 데이터를 몇 번 반복해서 볼지
    imgsz=args.imgsz,                # 이미지 크기 (640x640)
    batch=args.batch_size,    # 한 번에 몇 장씩 학습할지 (GPU 메모리에 영향)
    project=args.output_dir,  # 결과물(모델 파일, 그래프)을 저장할 경로
    name='args.name'   # 실험 이름
)
```

도커 빌드 방법
```bash
gcloud builds submit --tag asia-northeast3-docker.pkg.dev/knu-team-02/safehome-repo/yolo-train:v1 .
```

# gcloud storage cp -r gs://[버킷명]/[경로] [로컬경로]
```bash
gcloud storage cp -r gs://safety-furniture-project-v1/datav1/test ./datasets/
```