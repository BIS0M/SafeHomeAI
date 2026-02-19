# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# 실행 방법
flutter run -d chrome

# 프론트 firebase hosting 배포 방법 (터미널로)

사전 준비: Node.js 설치하기, 그리고 bash를 이용해 설치
```bash
npm install -g firebase-tools
```

경로 SafeHomeAI/frontend로 이동
```bash
firebase init
```
- hosting 하나에만 별표되게끔 설정

- Project Setup: Use an existing project -> knu-team-02

- Public directory: build/web (직접 입력)

- Single-page app: Yes

- GitHub Action: No

- Overwrite index.html: No

이후 배포:
```bash
firebase deploy --only hosting
```