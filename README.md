# SafeHomeAI
Modeling

> conda 가상환경 라이브러리 / 패키지 정리 방법
저장: conda env export > environment.yaml
requiremets.txt 저장: pip list --format=freeze > requirements.txt

불러오기: ```conda env update -f ml.yml```
environment.yaml 가상환경 새로 만들기: ```conda env create -f environment.yaml```
requirements.txt 불러오기: python -m pip install -r requirements.txt

> github를 활용한 협업 방법:
> 각자 맡은 역할에서의 README.md, requirements.txt, Dockerfile, environments.yaml 등의 파일들은 본인의 폴더 안에 넣어서 push해주세요. (conflict 방지 차원)
