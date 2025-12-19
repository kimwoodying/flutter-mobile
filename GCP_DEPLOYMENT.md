# GCP를 사용한 챗봇 백엔드 배포 가이드

이 가이드는 Flutter 앱의 챗봇 기능을 GCP(Google Cloud Platform)로 배포하여 `34.42.223.43` IP를 사용하는 방법을 설명합니다.

## 전제 조건

- Google Cloud Platform 계정
- GCP CLI 설치
- 백엔드 코드 (Python FastAPI 등)
- Flutter 프로젝트

## 1. GCP 프로젝트 설정

### 1.1 GCP CLI 설치 및 로그인
```bash
# GCP CLI 다운로드 및 설치
# https://cloud.google.com/sdk/docs/install 에서 설치

# 로그인
gcloud auth login

# 프로젝트 생성 또는 선택
gcloud projects create your-chatbot-project --name="Chatbot Project"
gcloud config set project your-chatbot-project
```

### 1.2 App Engine 활성화
```bash
gcloud services enable appengine.googleapis.com
gcloud app create --region=asia-northeast1
```

## 2. 백엔드 코드 준비

### 2.1 프로젝트 구조
```
backend/
├── main.py              # FastAPI 앱
├── requirements.txt     # Python 의존성
├── app.yaml            # App Engine 설정
└── Dockerfile          # (선택) 컨테이너화
```

### 2.2 main.py 예시
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import openai  # 또는 다른 LLM 라이브러리

app = FastAPI(title="Chatbot API")

class ChatRequest(BaseModel):
    message: str
    session_id: str = None
    metadata: dict = None

class ChatResponse(BaseModel):
    reply: str
    sources: list = []

@app.post("/api/chat/")
async def chat_endpoint(request: ChatRequest):
    try:
        # 챗봇 로직 구현
        # OpenAI, Google Gemini 등 사용
        reply = generate_chat_response(request.message)
        return ChatResponse(reply=reply, sources=[])
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def generate_chat_response(message: str) -> str:
    # 실제 챗봇 로직
    return f"안녕하세요! '{message}'에 대한 답변입니다."
```

### 2.3 requirements.txt
```
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
openai==1.3.0  # 챗봇에 따라 변경
```

### 2.4 app.yaml
```yaml
runtime: python311
entrypoint: uvicorn main:app --host 0.0.0.0 --port 8080

env_variables:
  OPENAI_API_KEY: "your-openai-key"  # 환경변수 설정
```

## 3. GCP에 배포

### 3.1 App Engine 배포
```bash
cd backend

# 배포
gcloud app deploy

# 배포 상태 확인
gcloud app browse
```

배포가 완료되면 GCP에서 URL을 제공합니다 (예: `https://your-project-id.appspot.com`).

## 4. Flutter 앱 설정 변경

### 4.1 api_config.dart 수정
`lib/config/api_config.dart` 파일을 열고 리모트 URL을 GCP URL로 변경:

```dart
class ApiConfig {
  const ApiConfig._();

  static const bool _useLocalBackend = bool.fromEnvironment(
    'USE_LOCAL_BACKEND',
    defaultValue: false,  // 기본값을 false로 변경
  );

  static const String _localBaseUrl = 'http://127.0.0.1:8000';
  static const String _remoteBaseUrl = 'https://your-project-id.appspot.com';  // GCP URL
  static String get _localChatBaseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8001' : 'http://127.0.0.1:8001';
  static const String _remoteChatBaseUrl = 'https://your-project-id.appspot.com';  // GCP URL

  // ... 나머지 코드는 동일
}
```

### 4.2 앱 실행
```bash
# GCP 백엔드 사용
flutter run --dart-define=USE_LOCAL_BACKEND=false
```

## 5. 고정 IP 설정 (선택사항)

GCP에서 고정 IP를 사용하려면:

### 5.1 Cloud Load Balancer 사용
```bash
# 정적 IP 예약
gcloud compute addresses create chatbot-ip --global

# IP 주소 확인
gcloud compute addresses describe chatbot-ip --global
```

### 5.2 도메인 연결
고정 IP를 도메인에 연결하여 `34.42.223.43` 대신 사용.

## 6. 모니터링 및 로깅

### 6.1 로그 확인
```bash
gcloud app logs tail -s default
```

### 6.2 Cloud Monitoring 설정
GCP Console에서 모니터링 대시보드 설정.

## 7. 보안 고려사항

- API 키는 Secret Manager 사용
- CORS 설정 (필요시)
- 인증/인가 구현
- HTTPS 강제

## 8. 비용 최적화

- App Engine은 트래픽에 따라 자동 스케일링
- Cloud Functions로 전환 고려 (저비용)
- 모니터링으로 불필요한 리소스 정리

## 문제 해결

### 배포 실패 시
```bash
gcloud app logs read
```

### API 연결 실패 시
- GCP 방화벽 설정 확인
- `app.yaml` 엔트리포인트 확인
- Flutter에서 `--dart-define=USE_LOCAL_BACKEND=false` 사용 확인

이 가이드를 따라 GCP에 챗봇을 배포하고 Flutter 앱에서 연결할 수 있습니다.