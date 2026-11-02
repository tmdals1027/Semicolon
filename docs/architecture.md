# 프로젝트 구조와 기술 결정

## 확정한 방향

- 처음에는 혼자 개발하며, 하나의 저장소에서 화면과 서버를 함께 관리합니다.
- 프론트엔드는 React + TypeScript + Vite, 스타일은 CSS로 시작합니다.
- 백엔드는 Java 21 + Spring Boot 4.1.2입니다. 공식 Spring Initializr의 Gradle 프로젝트를 기반으로 합니다.
- 데이터 저장소는 MySQL 8.4로 선택했습니다. 초기 연결 확인 단계에는 DB 의존성이 없습니다.

## 요청이 이동하는 과정

1. 브라우저가 React 화면을 엽니다.
2. 화면이 `/api/health`로 서버 상태를 요청합니다.
3. 개발 중에는 Vite가 요청을 `http://localhost:8080`으로 전달합니다.
4. Spring Boot가 `status`와 `service`를 JSON으로 반환합니다.
5. 화면이 결과를 확인하고 연결 성공 또는 연결 대기를 표시합니다.

현재 공개하는 API는 읽기 전용 상태 확인 API 하나입니다. 실제 회원 데이터는 아직 저장하거나 처리하지 않습니다.

## 코드 위치

- `frontend/src/App.tsx`: 초기 연결 확인 화면과 상태 처리
- `frontend/src/App.css`, `index.css`: 화면 스타일
- `frontend/vite.config.ts`: 개발 포트와 `/api` 전달 설정
- `backend/src/main/java/kr/semicolon/SemicolonApplication.java`: 서버 시작점
- `backend/src/main/java/kr/semicolon/health/`: 상태 API
- `backend/src/test/java/kr/semicolon/health/`: 상태 API의 실제 HTTP 응답 검사

일정 기능을 추가할 때 `backend/.../schedule/`처럼 기능별로 코드를 모읍니다.
프론트엔드도 기능이 생길 때 공통 화면 요소와 기능별 화면을 나눕니다. 필요하기 전에 빈 계층과 파일을 늘리지 않습니다.

## 이후 결정할 내용

- 학회원 가입과 승인 방식, 로그인 방식
- 운영진과 회계 담당자의 권한 범위
- MySQL 테이블과 관계, Spring Data JPA 연결, DB 변경 적용 도구
- 사진·자료 파일 저장소와 업로드 제한
- 배포 환경, 주소, 운영 비용

비공개 회원·회비 데이터를 처리하는 API를 추가할 때는 로그인과 서버의 권한 검사를 함께 구현합니다.
배포 시 프론트엔드 정적 파일과 백엔드 서버, `/api` 전달 설정을 함께 구성해야 합니다.
