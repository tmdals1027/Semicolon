# Semicolon

세미콜론 학회 홈페이지입니다. React 화면과 Java/Spring Boot 서버를 한 저장소에서 관리합니다.

현재는 **프로젝트 초기 세팅** 단계입니다. 프론트엔드가 서버의 `/api/health`를 호출하고 연결 결과를 표시합니다.
Figma의 실제 학회 화면, 로그인, 회원 정보와 회비 처리는 이후 기능 설계에 맞춰 구현합니다.

## 선택한 기술

| 구분 | 기술 |
| --- | --- |
| 화면 | React 19, TypeScript 7, Vite 8, CSS |
| 서버 | Java 21, Spring Boot 4.1.2, Gradle Wrapper |
| 데이터베이스 | MySQL 8.4 — 선택 및 로컬 실행 설정 준비, 서버 연동은 후속 작업 |

## 폴더 안내

```text
Semicolon/
├─ frontend/      화면과 프론트엔드 실행 설정
├─ backend/       서버와 서버 테스트
├─ docs/          기술 결정, 기능 설계 초안, 작업 규칙
├─ .github/       자동 검사와 작업·코드 검토 양식
├─ compose.yaml  선택 사항: 로컬 MySQL 실행
├─ .env.example  로컬 DB 설정 예시
└─ README.md      시작 안내
```

## 필요한 프로그램

- Node.js **24 LTS**와 npm
- **JDK 21** (`java -version`, `javac -version`으로 확인)
- Git
- 선택 사항: MySQL 컨테이너를 사용할 때 Docker와 Docker Compose

Gradle은 따로 설치하지 않습니다. `backend`의 Wrapper가 지정 버전을 받습니다.
첫 실행에는 의존성을 받기 위한 인터넷 연결이 필요합니다.

## 처음 실행하기 — Windows PowerShell

저장소를 내려받은 뒤 VS Code에서 `Semicolon` 폴더 전체를 엽니다.

```powershell
git clone https://github.com/tmdals1027/Semicolon.git
cd Semicolon
```

### 1. 서버 실행

첫 번째 터미널에서 실행합니다.

```powershell
cd backend
.\gradlew.bat bootRun
```

`Started SemicolonApplication` 로그가 보이면 준비 완료입니다.
브라우저에서 <http://localhost:8080/api/health>를 열면 다음 결과가 나옵니다.

```json
{"status":"UP","service":"semicolon-backend"}
```

### 2. 화면 실행

VS Code에서 **새 터미널**을 엽니다. 저장소 최상위 폴더를 기준으로 실행합니다.

```powershell
cd frontend
npm.cmd ci
npm.cmd run dev
```

<http://127.0.0.1:5173>에 접속합니다. **서버 연결 성공**이 보이면 화면과 서버가 모두 동작합니다.
`npm.cmd`는 PowerShell의 스크립트 실행 정책과 관계없이 npm을 실행하기 위해 사용합니다.
서버와 화면을 실행한 터미널은 켜 둡니다. 각 터미널에서 `Ctrl+C`로 종료할 수 있습니다.

macOS/Linux에서는 서버 명령을 `./gradlew bootRun`, npm 명령을 `npm ci`, `npm run dev`로 실행합니다.

### 연결이 안 될 때

- 서버 터미널에 실행 오류가 없는지 확인합니다.
- 서버가 준비된 뒤 화면의 **다시 확인하기**를 누릅니다.
- 기본 포트는 서버 `8080`, 화면 `5173`입니다. 같은 포트를 사용하는 다른 프로그램을 확인합니다.
- 서버 주소를 바꾸려면 `frontend/.env.example`을 `frontend/.env`로 복사하고 `BACKEND_URL`을 수정합니다. 화면 서버를 다시 실행해야 적용됩니다.
- JDK를 찾지 못하면 `JAVA_HOME`이 JDK 21 설치 폴더를 가리키는지 확인하고 터미널을 다시 엽니다.

프론트엔드는 `/api`로 요청하고, 개발 중에는 Vite가 이 요청을 Spring Boot로 전달합니다.
배포할 때에도 `/api`가 실제 서버로 전달되도록 별도 배포 설정이 필요합니다.

## 검사 방법

프론트엔드 폴더에서:

```powershell
npm.cmd run build
npm.cmd run lint
```

백엔드 폴더에서:

```powershell
.\gradlew.bat test bootJar
```

서버 테스트는 임의의 빈 포트로 서버를 띄우고 상태 API의 응답을 확인합니다. MySQL은 필요하지 않습니다.
깃허브에서도 `main`으로 올리거나 Pull Request를 만들면 같은 빌드·테스트를 자동 실행합니다.

## MySQL 준비 — 선택 사항

**현재 상태 확인 API는 DB를 사용하지 않습니다.** 지금 화면·서버 연결을 확인하는 데 Docker나 MySQL 설치는 필요하지 않습니다.
MySQL과 Spring Data JPA 연동, 테이블 설계, DB 변경 기록은 다음 데이터 설계 단계에서 추가합니다.

Docker가 준비돼 있다면 저장소 최상위 폴더에서 로컬 DB를 준비할 수 있습니다.

```powershell
Copy-Item .env.example .env
# .env의 두 비밀번호를 로컬 개발용 값으로 수정한 다음 실행합니다.
docker compose up -d
docker compose ps
```

접속 정보: `127.0.0.1:3306`, DB `semicolon`, 사용자 `semicolon`, 비밀번호는 `.env`의 `MYSQL_PASSWORD` 값입니다.
중지할 때는 `docker compose stop`을 실행합니다. 데이터는 Docker 볼륨에 유지됩니다.
현재 개발 환경에서 Docker 실행 여부는 별도로 확인해야 합니다.

`.env`와 로컬 설정은 깃허브에 저장하지 않습니다. 공유할 설정의 이름과 예시는 `.env.example`에 적습니다.

## 다음 작업

1. [기능 설계 초안](docs/feature-plan.md)의 미정 항목을 결정합니다.
2. 회원과 운영진의 권한을 정하고 DB와 API를 설계합니다.
3. 일정 조회부터 화면과 서버를 연결하며 기능을 구현합니다.

- [프로젝트 구조와 기술 결정](docs/architecture.md)
- [작업 방법](docs/workflow.md)
- [Figma 디자인](https://www.figma.com/design/CIYobCa73UFy3nl1X1SRxH/semicolon?node-id=31-255)
