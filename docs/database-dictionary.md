# DB 테이블·컬럼 사전

MySQL 8.4용 v0.1 설계 초안입니다. [설계 원칙과 미정 정책](database-design.md)을 함께 확인하세요.

PK는 기본키, FK는 다른 테이블 참조, NULL 허용은 아직 정해지지 않았거나 없는 값을 뜻합니다. 신청 화면의 필수 입력은 이름·학번·이메일·비밀번호 네 가지이며, 나머지 시스템 필드는 서버가 기록합니다.

## members — 회원 계정

영역: 회원·권한

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| name | VARCHAR(100) | 예 | — | 가입 신청 이름 |
| student_number | VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin | 예 | — | 문자열 학번. 앞자리 0 보존 |
| email | VARCHAR(254) COLLATE utf8mb4_0900_as_ci | 예 | — | 이메일. 앞뒤 공백 제거·대소문자 통일 정책 적용 |
| password_hash | VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin | 예 | — | PasswordEncoder의 해시만 저장. 조회 응답에서 제외 |
| status | ENUM('PENDING','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') | 예 | 'PENDING' | 승인 상태. 권한과 분리 |
| applied_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 현재 가입 신청 시각 |
| approved_at | DATETIME(6) | 아니오 | — | 마지막 승인 시각 |
| approved_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 마지막 승인 운영진. 최초 관리자 생성 시 시스템 승인 가능 |
| email_verified_at | DATETIME(6) | 아니오 | — | 이메일 확인 시각. 인증 절차 도입 전에는 NULL |
| version | INT UNSIGNED | 예 | 0 | 동시 승인·수정 충돌 검사 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

중복 방지: (student_number), (email).

주요 조회 인덱스: (status, applied_at).

DB 값 제약:

- ``status` <> 'APPROVED' OR `approved_at` IS NOT NULL`

## roles — 운영 권한 코드

영역: 회원·권한

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| code | VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin | 예 | PK | MEMBER / STAFF / TREASURER / ADMIN |
| name | VARCHAR(50) | 예 | — | 화면에 표시할 권한 이름 |

## member_roles — 회원에게 부여한 권한

영역: 회원·권한

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| member_id | BIGINT UNSIGNED | 예 | PK; FK → members.id | 권한을 받은 회원 |
| role_code | VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin | 예 | PK; FK → roles.code | 부여한 권한 |
| granted_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 권한을 부여한 관리자. 최초 설정은 시스템 처리 |
| granted_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 권한 부여 시각 |
| expires_at | DATETIME(6) | 아니오 | — | 권한 만료 시각. 일반 회원 권한은 만료 없이 둘 수 있음 |

DB 값 제약:

- ``expires_at` IS NULL OR `expires_at` > `granted_at``

## membership_reviews — 가입·회원 상태 변경 이력

영역: 회원·권한

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| member_id | BIGINT UNSIGNED | 예 | FK → members.id | 상태가 변경된 회원 |
| from_status | ENUM('PENDING','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') | 예 | — | 변경 전 상태 |
| to_status | ENUM('PENDING','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') | 예 | — | 변경 후 상태 |
| reviewed_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 처리 운영진. 본인 재신청이나 시스템 처리도 구분해 기록 |
| reason | VARCHAR(500) | 아니오 | — | 반려·정지·복구 등의 처리 이유 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

주요 조회 인덱스: (member_id, created_at).

DB 값 제약:

- ``from_status` <> `to_status``

## club_terms — 학기·운영 기수

영역: 조직·프로젝트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| name | VARCHAR(100) | 예 | — | 예: 2026년 2학기 운영진 |
| academic_year | SMALLINT UNSIGNED | 예 | — | 학년도 |
| semester | TINYINT UNSIGNED | 예 | — | 1학기 또는 2학기 |
| generation_label | VARCHAR(50) | 아니오 | — | 학회 기수 표시 |
| starts_on | DATE | 예 | — | 학기 시작 날짜 |
| ends_on | DATE | 예 | — | 학기 종료 날짜 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

중복 방지: (academic_year, semester).

DB 값 제약:

- ``semester` IN (1, 2)`
- ``ends_on` >= `starts_on``

## departments — 학회 부서

영역: 조직·프로젝트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| name | VARCHAR(100) | 예 | — | 기획부·홍보부·총무부 등 |
| description | TEXT | 아니오 | — | 부서 설명 |
| sort_order | INT UNSIGNED | 예 | 0 | 표시 순서 |
| is_active | BOOLEAN | 예 | TRUE | 현재 사용하는 부서 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

중복 방지: (name).

DB 값 제약:

- ``is_active` IN (0, 1)`

## officer_assignments — 기수별 운영진 조직도

영역: 조직·프로젝트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| term_id | BIGINT UNSIGNED | 예 | FK → club_terms.id | 운영 학기 |
| member_id | BIGINT UNSIGNED | 예 | FK → members.id | 운영진 회원 |
| department_id | BIGINT UNSIGNED | 아니오 | FK → departments.id | 소속 부서. 학회장 등은 NULL 가능 |
| position_title | VARCHAR(100) | 예 | — | 학회장·기획부장 등의 직책. 시스템 권한과 별개 |
| sort_order | INT UNSIGNED | 예 | 0 | 표시 순서 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

중복 방지: (term_id, member_id, position_title).

주요 조회 인덱스: (term_id, department_id, sort_order).

## projects — 학회 프로젝트

영역: 조직·프로젝트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| term_id | BIGINT UNSIGNED | 아니오 | FK → club_terms.id | 대표 학기. 장기 프로젝트는 NULL 가능 |
| title | VARCHAR(200) | 예 | — | 프로젝트 이름 |
| description | TEXT | 예 | — | 설명 |
| status | ENUM('PLANNING','ACTIVE','COMPLETED','ARCHIVED') | 예 | 'PLANNING' | 진행 상태 |
| progress_percent | TINYINT UNSIGNED | 예 | 0 | 0~100 진행률 |
| tech_stack | JSON | 아니오 | — | 기술 이름의 배열. 회원 관계 등은 JSON에 저장하지 않음 |
| repository_url | VARCHAR(2048) | 아니오 | — | 프로젝트 코드 주소 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 생성자 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (status, updated_at).

DB 값 제약:

- ``progress_percent` <= 100`
- ``tech_stack` IS NULL OR JSON_TYPE(`tech_stack`) = 'ARRAY'`

## project_members — 프로젝트 참여자

영역: 조직·프로젝트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| project_id | BIGINT UNSIGNED | 예 | PK; FK → projects.id | 참여 프로젝트 |
| member_id | BIGINT UNSIGNED | 예 | PK; FK → members.id | 참여 회원 |
| project_role | ENUM('LEAD','MEMBER') | 예 | 'MEMBER' | 프로젝트 내 역할. 사이트 운영 권한과 별개 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

## schedules — 내부 일정

영역: 일정·게시물·파일

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| title | VARCHAR(200) | 예 | — | 일정 제목 |
| description | TEXT | 아니오 | — | 상세 안내 |
| starts_at | DATETIME(6) | 예 | — | 시작 시각(UTC) |
| ends_at | DATETIME(6) | 예 | — | 종료 시각(UTC), 종료 경계 제외 |
| all_day | BOOLEAN | 예 | FALSE | 종일 일정 여부 |
| location | VARCHAR(255) | 아니오 | — | 장소 또는 온라인 안내 |
| category | ENUM('MEETING','STUDY','SEMINAR','SOCIAL','OTHER') | 예 | 'OTHER' | 표시 분류 |
| visibility | ENUM('MEMBERS','STAFF') | 예 | 'MEMBERS' | 내부 회원용 또는 운영진 전용. 공개 일정은 현재 설계 범위에 없음 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 등록자 |
| updated_by | BIGINT UNSIGNED | 예 | FK → members.id | 마지막 수정자 |
| deleted_at | DATETIME(6) | 아니오 | — | 삭제 표시 시각 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (visibility, starts_at), (ends_at).

DB 값 제약:

- ``ends_at` > `starts_at``
- ``all_day` IN (0, 1)`

## files — 파일 메타데이터

영역: 일정·게시물·파일

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| storage_key | VARCHAR(512) CHARACTER SET ascii COLLATE ascii_bin | 예 | — | 비공개 파일 저장소의 객체 키 |
| original_name | VARCHAR(255) | 예 | — | 업로드 파일 이름 |
| content_type | VARCHAR(127) | 예 | — | 파일 MIME 유형 |
| byte_size | BIGINT UNSIGNED | 예 | — | 바이트 크기 |
| sha256 | CHAR(64) CHARACTER SET ascii COLLATE ascii_bin | 아니오 | — | 내용 검증용 해시 |
| storage_state | ENUM('PENDING','READY','DELETED') | 예 | 'PENDING' | 업로드 완료 상태 |
| uploaded_by | BIGINT UNSIGNED | 예 | FK → members.id | 업로더 |
| deleted_at | DATETIME(6) | 아니오 | — | 삭제 표시 시각 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

중복 방지: (storage_key).

주요 조회 인덱스: (uploaded_by, created_at).

## posts — 공지·공개 활동·회의록·자료실 게시물

영역: 일정·게시물·파일

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| kind | ENUM('NOTICE','ACTIVITY','MINUTES','RESOURCE') | 예 | — | 게시물 종류 |
| title | VARCHAR(200) | 예 | — | 제목 |
| body | MEDIUMTEXT | 예 | — | 본문. 초기에는 일반 텍스트나 제한된 Markdown |
| category | VARCHAR(50) | 아니오 | — | 세미나·스터디·서식 등의 분류 |
| visibility | ENUM('PUBLIC','MEMBERS','STAFF') | 예 | 'MEMBERS' | 공개 범위 |
| publication_status | ENUM('DRAFT','PUBLISHED','ARCHIVED') | 예 | 'DRAFT' | 작성·공개 상태 |
| project_id | BIGINT UNSIGNED | 아니오 | FK → projects.id | 관련 프로젝트 |
| schedule_id | BIGINT UNSIGNED | 아니오 | FK → schedules.id | 관련 내부 일정 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 작성자 |
| updated_by | BIGINT UNSIGNED | 예 | FK → members.id | 마지막 수정자 |
| published_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 공개 처리자 |
| published_at | DATETIME(6) | 아니오 | — | 공개 시각 |
| deleted_at | DATETIME(6) | 아니오 | — | 삭제 표시 시각 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (kind, visibility, publication_status, published_at).

DB 값 제약:

- ``kind` NOT IN ('MINUTES', 'RESOURCE') OR `visibility` <> 'PUBLIC'`
- ``publication_status` <> 'PUBLISHED' OR (`published_at` IS NOT NULL AND `published_by` IS NOT NULL)`

## meeting_details — 회의록 추가 정보

영역: 일정·게시물·파일

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| post_id | BIGINT UNSIGNED | 예 | PK; FK → posts.id | MINUTES 종류 게시물 |
| held_at | DATETIME(6) | 예 | — | 회의 시각(UTC) |
| location | VARCHAR(255) | 아니오 | — | 회의 장소 |

## meeting_attendees — 회의 참석 회원

영역: 일정·게시물·파일

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| post_id | BIGINT UNSIGNED | 예 | PK; FK → meeting_details.post_id | 회의록 |
| member_id | BIGINT UNSIGNED | 예 | PK; FK → members.id | 참석 회원 |

## post_attachments — 게시물 첨부 파일

영역: 일정·게시물·파일

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| post_id | BIGINT UNSIGNED | 예 | PK; FK → posts.id | 첨부된 게시물 |
| file_id | BIGINT UNSIGNED | 예 | PK; FK → files.id | 첨부 파일 |
| sort_order | INT UNSIGNED | 예 | 0 | 표시 순서 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

## photo_albums — 행사 사진 앨범

영역: 사진·이벤트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| title | VARCHAR(200) | 예 | — | 앨범 이름 |
| description | TEXT | 아니오 | — | 앨범 설명 |
| occurred_on | DATE | 아니오 | — | 행사 날짜 |
| visibility | ENUM('PUBLIC','MEMBERS') | 예 | 'MEMBERS' | 공개용 선정 앨범 또는 내부 앨범 |
| publication_status | ENUM('DRAFT','PUBLISHED','ARCHIVED') | 예 | 'DRAFT' | 공개 상태 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 생성자 |
| published_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 공개 처리자 |
| published_at | DATETIME(6) | 아니오 | — | 공개 시각 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (visibility, publication_status, occurred_on).

DB 값 제약:

- ``publication_status` <> 'PUBLISHED' OR (`published_at` IS NOT NULL AND `published_by` IS NOT NULL)`

## album_photos — 앨범의 사진

영역: 사진·이벤트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| album_id | BIGINT UNSIGNED | 예 | FK → photo_albums.id | 사진 앨범 |
| file_id | BIGINT UNSIGNED | 예 | FK → files.id | 사진 원본 메타데이터 |
| alt_text | VARCHAR(500) | 아니오 | — | 사진 설명 |
| sort_order | INT UNSIGNED | 예 | 0 | 표시 순서 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

중복 방지: (album_id, file_id).

주요 조회 인덱스: (album_id, sort_order).

## dues_campaigns — 학기·행사별 회비 항목

영역: 회비·정산

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| term_id | BIGINT UNSIGNED | 예 | FK → club_terms.id | 회비가 속한 학기 |
| schedule_id | BIGINT UNSIGNED | 아니오 | FK → schedules.id | 관련 행사 일정 |
| title | VARCHAR(200) | 예 | — | 예: 2026-2 학회비, 가을 MT 참가비 |
| default_amount_won | BIGINT UNSIGNED | 예 | — | 대상자에게 기본 부과할 원화 금액 |
| due_at | DATETIME(6) | 예 | — | 납부 마감 시각(UTC) |
| payment_bank_name | VARCHAR(100) | 아니오 | — | 입금 안내 은행 |
| payment_account_number | VARCHAR(100) | 아니오 | — | 학회 입금 계좌 안내. 숫자형으로 저장하지 않음 |
| payment_account_holder | VARCHAR(100) | 아니오 | — | 입금 계좌 예금주 안내 |
| payment_note | VARCHAR(500) | 아니오 | — | 입금자명 작성 방법 등 안내 |
| status | ENUM('DRAFT','OPEN','CLOSED') | 예 | 'DRAFT' | 작성·납부 안내·마감 상태 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 회계 담당 등록자 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (term_id, status, due_at).

DB 값 제약:

- ``default_amount_won` > 0`

## dues_charges — 회원별 부과·납부 상태

영역: 회비·정산

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| campaign_id | BIGINT UNSIGNED | 예 | FK → dues_campaigns.id | 회비 항목 |
| member_id | BIGINT UNSIGNED | 예 | FK → members.id | 납부 대상 회원 |
| amount_won | BIGINT UNSIGNED | 예 | — | 이 회원에게 확정 부과한 금액. 항목 기본 금액과 별개 스냅샷 |
| status | ENUM('UNPAID','PAYMENT_REPORTED','PAID','WAIVED') | 예 | 'UNPAID' | 미납 / 입금 신고·확인 대기 / 납부 완료 / 면제 |
| payment_reported_at | DATETIME(6) | 아니오 | — | 회원이 입금했다고 알린 시각 |
| reviewed_at | DATETIME(6) | 아니오 | — | 운영진이 납부 또는 면제를 확인한 시각 |
| reviewed_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 납부·면제 처리한 회계 권한자 |
| version | INT UNSIGNED | 예 | 0 | 중복 확인·동시 수정 방지 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

중복 방지: (campaign_id, member_id).

주요 조회 인덱스: (member_id, status), (campaign_id, status).

DB 값 제약:

- ``amount_won` > 0`
- ``status` <> 'PAYMENT_REPORTED' OR `payment_reported_at` IS NOT NULL`
- ``status` NOT IN ('PAID', 'WAIVED') OR (`reviewed_at` IS NOT NULL AND `reviewed_by` IS NOT NULL)`

## dues_status_events — 회비 상태 변경 기록

영역: 회비·정산

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| charge_id | BIGINT UNSIGNED | 예 | FK → dues_charges.id | 변경된 부과 내역 |
| from_status | ENUM('UNPAID','PAYMENT_REPORTED','PAID','WAIVED') | 아니오 | — | 변경 전 상태. 최초 부과는 NULL |
| to_status | ENUM('UNPAID','PAYMENT_REPORTED','PAID','WAIVED') | 예 | — | 변경 후 상태 |
| actor_id | BIGINT UNSIGNED | 아니오 | FK → members.id | 처리 회원·운영진. 최초 부과는 시스템 기록 가능 |
| reason | VARCHAR(500) | 아니오 | — | 반려·정정·면제 이유 |
| previous_amount_won | BIGINT UNSIGNED | 아니오 | — | 변경 전 금액 |
| new_amount_won | BIGINT UNSIGNED | 예 | — | 기록 시점 부과 금액 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

주요 조회 인덱스: (charge_id, created_at).

## settlements — 행사 정산 묶음

영역: 회비·정산

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| schedule_id | BIGINT UNSIGNED | 아니오 | FK → schedules.id | 관련 행사 일정 |
| title | VARCHAR(200) | 예 | — | 정산 이름 |
| status | ENUM('DRAFT','FINALIZED','CANCELLED') | 예 | 'DRAFT' | 계산 중 / 확정 / 취소 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 정산 작성자 |
| finalized_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 확정한 회계 권한자 |
| finalized_at | DATETIME(6) | 아니오 | — | 확정 시각 |
| version | INT UNSIGNED | 예 | 0 | 동시 수정 방지 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (status, created_at).

DB 값 제약:

- ``status` <> 'FINALIZED' OR (`finalized_by` IS NOT NULL AND `finalized_at` IS NOT NULL)`

## settlement_expenses — 정산 지출 항목

영역: 회비·정산

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| settlement_id | BIGINT UNSIGNED | 예 | FK → settlements.id | 정산 묶음 |
| category | VARCHAR(50) | 예 | — | 숙박·식비·교통 등 |
| description | VARCHAR(255) | 예 | — | 지출 설명 |
| quantity | INT UNSIGNED | 예 | 1 | 수량 |
| unit_price_won | BIGINT UNSIGNED | 예 | — | 원화 단가 |
| spent_on | DATE | 아니오 | — | 지출 날짜 |
| paid_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 선결제한 회원. 미기록 가능 |
| receipt_file_id | BIGINT UNSIGNED | 아니오 | FK → files.id | 내부 영수증 파일 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

DB 값 제약:

- ``quantity` > 0`

## settlement_participants — 정산 참가자와 확정 분담액

영역: 회비·정산

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| settlement_id | BIGINT UNSIGNED | 예 | PK; FK → settlements.id | 정산 묶음 |
| member_id | BIGINT UNSIGNED | 예 | PK; FK → members.id | 참가 회원 |
| is_exempt | BOOLEAN | 예 | FALSE | 분담 면제 여부 |
| allocated_amount_won | BIGINT UNSIGNED | 아니오 | — | 확정 당시 분담액. 계산 중에는 NULL 가능 |
| note | VARCHAR(255) | 아니오 | — | 면제 이유 등 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

DB 값 제약:

- ``is_exempt` IN (0, 1)`
- ``is_exempt` = 0 OR `allocated_amount_won` IS NULL OR `allocated_amount_won` = 0`

## giveaways — 이벤트 당첨 발표

영역: 사진·이벤트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| title | VARCHAR(200) | 예 | — | 이벤트 이름 |
| description | TEXT | 아니오 | — | 진행 안내 |
| announce_at | DATETIME(6) | 예 | — | 발표 예정 시각(UTC) |
| status | ENUM('DRAFT','PUBLISHED','CLOSED') | 예 | 'DRAFT' | 결과 준비·발표·종료 |
| created_by | BIGINT UNSIGNED | 예 | FK → members.id | 등록자 |
| published_by | BIGINT UNSIGNED | 아니오 | FK → members.id | 발표 처리자 |
| published_at | DATETIME(6) | 아니오 | — | 실제 발표 시각 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

주요 조회 인덱스: (status, announce_at).

DB 값 제약:

- ``status` <> 'PUBLISHED' OR (`published_by` IS NOT NULL AND `published_at` IS NOT NULL)`

## giveaway_entries — 이벤트 대상 회원과 결과

영역: 사진·이벤트

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| giveaway_id | BIGINT UNSIGNED | 예 | PK; FK → giveaways.id | 이벤트 |
| member_id | BIGINT UNSIGNED | 예 | PK; FK → members.id | 이벤트 대상 회원 |
| result | ENUM('PENDING','WINNER','NOT_WINNER') | 예 | 'PENDING' | 미발표 / 당첨 / 미당첨 |
| updated_by | BIGINT UNSIGNED | 예 | FK → members.id | 결과 수정 운영진 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |
| updated_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 마지막 변경 시각(UTC) |

## audit_logs — 중요 운영 작업 기록

영역: 회원·권한

| 컬럼 | 타입 | 필수 | 기본값·관계 | 의미 |
| --- | --- | --- | --- | --- |
| id | BIGINT UNSIGNED | 예 | PK; 자동 증가 | 내부 식별자. 학번과 별개 |
| actor_id | BIGINT UNSIGNED | 아니오 | FK → members.id | 작업자. 시스템 작업은 NULL |
| action | VARCHAR(64) | 예 | — | ROLE_GRANTED, ROLE_REVOKED, POST_PUBLISHED, SETTLEMENT_FINALIZED 등 |
| entity_type | VARCHAR(40) | 예 | — | 대상 종류 |
| entity_id | BIGINT UNSIGNED | 아니오 | — | 대상 식별자. 이력 참조이므로 일반 FK로 연결하지 않음 |
| details | JSON | 아니오 | — | 허용한 상태·역할 코드·이유만 기록. 비밀번호·토큰·개인정보 원문 제외 |
| created_at | DATETIME(6) | 예 | CURRENT_TIMESTAMP(6) | 생성 시각(UTC) |

주요 조회 인덱스: (entity_type, entity_id, created_at), (actor_id, created_at).
