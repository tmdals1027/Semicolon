-- Semicolon database design v0.1 / MySQL 8.4 / DRAFT

-- Design reference only. Not a Spring/Flyway migration; not applied automatically.

-- Review the assumptions in database-design.md before using an empty development database.

-- DATETIME values are written in UTC by the application. Amounts use whole KRW.



-- 회원 계정
CREATE TABLE `members` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `student_number` VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `email` VARCHAR(254) COLLATE utf8mb4_0900_as_ci NOT NULL,
  `password_hash` VARCHAR(255) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `status` ENUM('PENDING','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') NOT NULL DEFAULT 'PENDING',
  `applied_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `approved_at` DATETIME(6) NULL,
  `approved_by` BIGINT UNSIGNED NULL,
  `email_verified_at` DATETIME(6) NULL,
  `version` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_members_1` (`student_number`),
  UNIQUE KEY `uq_members_2` (`email`),
  KEY `idx_members_1` (`status`, `applied_at`),
  KEY `idx_members_2` (`approved_by`),
  CONSTRAINT `fk_members_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_members_1` CHECK (`status` <> 'APPROVED' OR `approved_at` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 운영 권한 코드
CREATE TABLE `roles` (
  `code` VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 회원에게 부여한 권한
CREATE TABLE `member_roles` (
  `member_id` BIGINT UNSIGNED NOT NULL,
  `role_code` VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `granted_by` BIGINT UNSIGNED NULL,
  `granted_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `expires_at` DATETIME(6) NULL,
  PRIMARY KEY (`member_id`, `role_code`),
  KEY `idx_member_roles_1` (`role_code`),
  KEY `idx_member_roles_2` (`granted_by`),
  CONSTRAINT `fk_member_roles_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_member_roles_role_code` FOREIGN KEY (`role_code`) REFERENCES `roles` (`code`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_member_roles_granted_by` FOREIGN KEY (`granted_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_member_roles_1` CHECK (`expires_at` IS NULL OR `expires_at` > `granted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 가입·회원 상태 변경 이력
CREATE TABLE `membership_reviews` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `member_id` BIGINT UNSIGNED NOT NULL,
  `from_status` ENUM('PENDING','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') NOT NULL,
  `to_status` ENUM('PENDING','APPROVED','REJECTED','SUSPENDED','WITHDRAWN') NOT NULL,
  `reviewed_by` BIGINT UNSIGNED NULL,
  `reason` VARCHAR(500) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_membership_reviews_1` (`member_id`, `created_at`),
  KEY `idx_membership_reviews_2` (`reviewed_by`),
  CONSTRAINT `fk_membership_reviews_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_membership_reviews_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_membership_reviews_1` CHECK (`from_status` <> `to_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 학기·운영 기수
CREATE TABLE `club_terms` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `academic_year` SMALLINT UNSIGNED NOT NULL,
  `semester` TINYINT UNSIGNED NOT NULL,
  `generation_label` VARCHAR(50) NULL,
  `starts_on` DATE NOT NULL,
  `ends_on` DATE NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_club_terms_1` (`academic_year`, `semester`),
  CONSTRAINT `chk_club_terms_1` CHECK (`semester` IN (1, 2)),
  CONSTRAINT `chk_club_terms_2` CHECK (`ends_on` >= `starts_on`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 학회 부서
CREATE TABLE `departments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` TEXT NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_departments_1` (`name`),
  CONSTRAINT `chk_departments_1` CHECK (`is_active` IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 기수별 운영진 조직도
CREATE TABLE `officer_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `term_id` BIGINT UNSIGNED NOT NULL,
  `member_id` BIGINT UNSIGNED NOT NULL,
  `department_id` BIGINT UNSIGNED NULL,
  `position_title` VARCHAR(100) NOT NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_officer_assignments_1` (`term_id`, `member_id`, `position_title`),
  KEY `idx_officer_assignments_1` (`term_id`, `department_id`, `sort_order`),
  KEY `idx_officer_assignments_2` (`member_id`),
  KEY `idx_officer_assignments_3` (`department_id`),
  CONSTRAINT `fk_officer_assignments_term_id` FOREIGN KEY (`term_id`) REFERENCES `club_terms` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_officer_assignments_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_officer_assignments_department_id` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 학회 프로젝트
CREATE TABLE `projects` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `term_id` BIGINT UNSIGNED NULL,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT NOT NULL,
  `status` ENUM('PLANNING','ACTIVE','COMPLETED','ARCHIVED') NOT NULL DEFAULT 'PLANNING',
  `progress_percent` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `tech_stack` JSON NULL,
  `repository_url` VARCHAR(2048) NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_projects_1` (`status`, `updated_at`),
  KEY `idx_projects_2` (`term_id`),
  KEY `idx_projects_3` (`created_by`),
  CONSTRAINT `fk_projects_term_id` FOREIGN KEY (`term_id`) REFERENCES `club_terms` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_projects_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_projects_1` CHECK (`progress_percent` <= 100),
  CONSTRAINT `chk_projects_2` CHECK (`tech_stack` IS NULL OR JSON_TYPE(`tech_stack`) = 'ARRAY')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 프로젝트 참여자
CREATE TABLE `project_members` (
  `project_id` BIGINT UNSIGNED NOT NULL,
  `member_id` BIGINT UNSIGNED NOT NULL,
  `project_role` ENUM('LEAD','MEMBER') NOT NULL DEFAULT 'MEMBER',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`project_id`, `member_id`),
  KEY `idx_project_members_1` (`member_id`),
  CONSTRAINT `fk_project_members_project_id` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_project_members_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 내부 일정
CREATE TABLE `schedules` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT NULL,
  `starts_at` DATETIME(6) NOT NULL,
  `ends_at` DATETIME(6) NOT NULL,
  `all_day` BOOLEAN NOT NULL DEFAULT FALSE,
  `location` VARCHAR(255) NULL,
  `category` ENUM('MEETING','STUDY','SEMINAR','SOCIAL','OTHER') NOT NULL DEFAULT 'OTHER',
  `visibility` ENUM('MEMBERS','STAFF') NOT NULL DEFAULT 'MEMBERS',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `updated_by` BIGINT UNSIGNED NOT NULL,
  `deleted_at` DATETIME(6) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_schedules_1` (`visibility`, `starts_at`),
  KEY `idx_schedules_2` (`ends_at`),
  KEY `idx_schedules_3` (`created_by`),
  KEY `idx_schedules_4` (`updated_by`),
  CONSTRAINT `fk_schedules_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_schedules_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_schedules_1` CHECK (`ends_at` > `starts_at`),
  CONSTRAINT `chk_schedules_2` CHECK (`all_day` IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 파일 메타데이터
CREATE TABLE `files` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `storage_key` VARCHAR(512) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `original_name` VARCHAR(255) NOT NULL,
  `content_type` VARCHAR(127) NOT NULL,
  `byte_size` BIGINT UNSIGNED NOT NULL,
  `sha256` CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
  `storage_state` ENUM('PENDING','READY','DELETED') NOT NULL DEFAULT 'PENDING',
  `uploaded_by` BIGINT UNSIGNED NOT NULL,
  `deleted_at` DATETIME(6) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_files_1` (`storage_key`),
  KEY `idx_files_1` (`uploaded_by`, `created_at`),
  CONSTRAINT `fk_files_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 공지·공개 활동·회의록·자료실 게시물
CREATE TABLE `posts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `kind` ENUM('NOTICE','ACTIVITY','MINUTES','RESOURCE') NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `body` MEDIUMTEXT NOT NULL,
  `category` VARCHAR(50) NULL,
  `visibility` ENUM('PUBLIC','MEMBERS','STAFF') NOT NULL DEFAULT 'MEMBERS',
  `publication_status` ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `project_id` BIGINT UNSIGNED NULL,
  `schedule_id` BIGINT UNSIGNED NULL,
  `created_by` BIGINT UNSIGNED NOT NULL,
  `updated_by` BIGINT UNSIGNED NOT NULL,
  `published_by` BIGINT UNSIGNED NULL,
  `published_at` DATETIME(6) NULL,
  `deleted_at` DATETIME(6) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_posts_1` (`kind`, `visibility`, `publication_status`, `published_at`),
  KEY `idx_posts_2` (`project_id`),
  KEY `idx_posts_3` (`schedule_id`),
  KEY `idx_posts_4` (`created_by`),
  KEY `idx_posts_5` (`updated_by`),
  KEY `idx_posts_6` (`published_by`),
  CONSTRAINT `fk_posts_project_id` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_posts_schedule_id` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_posts_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_posts_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_posts_published_by` FOREIGN KEY (`published_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_posts_1` CHECK (`kind` NOT IN ('MINUTES', 'RESOURCE') OR `visibility` <> 'PUBLIC'),
  CONSTRAINT `chk_posts_2` CHECK (`publication_status` <> 'PUBLISHED' OR (`published_at` IS NOT NULL AND `published_by` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 회의록 추가 정보
CREATE TABLE `meeting_details` (
  `post_id` BIGINT UNSIGNED NOT NULL,
  `held_at` DATETIME(6) NOT NULL,
  `location` VARCHAR(255) NULL,
  PRIMARY KEY (`post_id`),
  CONSTRAINT `fk_meeting_details_post_id` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 회의 참석 회원
CREATE TABLE `meeting_attendees` (
  `post_id` BIGINT UNSIGNED NOT NULL,
  `member_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`post_id`, `member_id`),
  KEY `idx_meeting_attendees_1` (`member_id`),
  CONSTRAINT `fk_meeting_attendees_post_id` FOREIGN KEY (`post_id`) REFERENCES `meeting_details` (`post_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_meeting_attendees_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 게시물 첨부 파일
CREATE TABLE `post_attachments` (
  `post_id` BIGINT UNSIGNED NOT NULL,
  `file_id` BIGINT UNSIGNED NOT NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`post_id`, `file_id`),
  KEY `idx_post_attachments_1` (`file_id`),
  CONSTRAINT `fk_post_attachments_post_id` FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_post_attachments_file_id` FOREIGN KEY (`file_id`) REFERENCES `files` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 행사 사진 앨범
CREATE TABLE `photo_albums` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT NULL,
  `occurred_on` DATE NULL,
  `visibility` ENUM('PUBLIC','MEMBERS') NOT NULL DEFAULT 'MEMBERS',
  `publication_status` ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `published_by` BIGINT UNSIGNED NULL,
  `published_at` DATETIME(6) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_photo_albums_1` (`visibility`, `publication_status`, `occurred_on`),
  KEY `idx_photo_albums_2` (`created_by`),
  KEY `idx_photo_albums_3` (`published_by`),
  CONSTRAINT `fk_photo_albums_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_photo_albums_published_by` FOREIGN KEY (`published_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_photo_albums_1` CHECK (`publication_status` <> 'PUBLISHED' OR (`published_at` IS NOT NULL AND `published_by` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 앨범의 사진
CREATE TABLE `album_photos` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `album_id` BIGINT UNSIGNED NOT NULL,
  `file_id` BIGINT UNSIGNED NOT NULL,
  `alt_text` VARCHAR(500) NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_album_photos_1` (`album_id`, `file_id`),
  KEY `idx_album_photos_1` (`album_id`, `sort_order`),
  KEY `idx_album_photos_2` (`file_id`),
  CONSTRAINT `fk_album_photos_album_id` FOREIGN KEY (`album_id`) REFERENCES `photo_albums` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_album_photos_file_id` FOREIGN KEY (`file_id`) REFERENCES `files` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 학기·행사별 회비 항목
CREATE TABLE `dues_campaigns` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `term_id` BIGINT UNSIGNED NOT NULL,
  `schedule_id` BIGINT UNSIGNED NULL,
  `title` VARCHAR(200) NOT NULL,
  `default_amount_won` BIGINT UNSIGNED NOT NULL,
  `due_at` DATETIME(6) NOT NULL,
  `payment_bank_name` VARCHAR(100) NULL,
  `payment_account_number` VARCHAR(100) NULL,
  `payment_account_holder` VARCHAR(100) NULL,
  `payment_note` VARCHAR(500) NULL,
  `status` ENUM('DRAFT','OPEN','CLOSED') NOT NULL DEFAULT 'DRAFT',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_dues_campaigns_1` (`term_id`, `status`, `due_at`),
  KEY `idx_dues_campaigns_2` (`schedule_id`),
  KEY `idx_dues_campaigns_3` (`created_by`),
  CONSTRAINT `fk_dues_campaigns_term_id` FOREIGN KEY (`term_id`) REFERENCES `club_terms` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_dues_campaigns_schedule_id` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_dues_campaigns_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_dues_campaigns_1` CHECK (`default_amount_won` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 회원별 부과·납부 상태
CREATE TABLE `dues_charges` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `campaign_id` BIGINT UNSIGNED NOT NULL,
  `member_id` BIGINT UNSIGNED NOT NULL,
  `amount_won` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('UNPAID','PAYMENT_REPORTED','PAID','WAIVED') NOT NULL DEFAULT 'UNPAID',
  `payment_reported_at` DATETIME(6) NULL,
  `reviewed_at` DATETIME(6) NULL,
  `reviewed_by` BIGINT UNSIGNED NULL,
  `version` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dues_charges_1` (`campaign_id`, `member_id`),
  KEY `idx_dues_charges_1` (`member_id`, `status`),
  KEY `idx_dues_charges_2` (`campaign_id`, `status`),
  KEY `idx_dues_charges_3` (`reviewed_by`),
  CONSTRAINT `fk_dues_charges_campaign_id` FOREIGN KEY (`campaign_id`) REFERENCES `dues_campaigns` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_dues_charges_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_dues_charges_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_dues_charges_1` CHECK (`amount_won` > 0),
  CONSTRAINT `chk_dues_charges_2` CHECK (`status` <> 'PAYMENT_REPORTED' OR `payment_reported_at` IS NOT NULL),
  CONSTRAINT `chk_dues_charges_3` CHECK (`status` NOT IN ('PAID', 'WAIVED') OR (`reviewed_at` IS NOT NULL AND `reviewed_by` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 회비 상태 변경 기록
CREATE TABLE `dues_status_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `charge_id` BIGINT UNSIGNED NOT NULL,
  `from_status` ENUM('UNPAID','PAYMENT_REPORTED','PAID','WAIVED') NULL,
  `to_status` ENUM('UNPAID','PAYMENT_REPORTED','PAID','WAIVED') NOT NULL,
  `actor_id` BIGINT UNSIGNED NULL,
  `reason` VARCHAR(500) NULL,
  `previous_amount_won` BIGINT UNSIGNED NULL,
  `new_amount_won` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_dues_status_events_1` (`charge_id`, `created_at`),
  KEY `idx_dues_status_events_2` (`actor_id`),
  CONSTRAINT `fk_dues_status_events_charge_id` FOREIGN KEY (`charge_id`) REFERENCES `dues_charges` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_dues_status_events_actor_id` FOREIGN KEY (`actor_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 행사 정산 묶음
CREATE TABLE `settlements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schedule_id` BIGINT UNSIGNED NULL,
  `title` VARCHAR(200) NOT NULL,
  `status` ENUM('DRAFT','FINALIZED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `finalized_by` BIGINT UNSIGNED NULL,
  `finalized_at` DATETIME(6) NULL,
  `version` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_settlements_1` (`status`, `created_at`),
  KEY `idx_settlements_2` (`schedule_id`),
  KEY `idx_settlements_3` (`created_by`),
  KEY `idx_settlements_4` (`finalized_by`),
  CONSTRAINT `fk_settlements_schedule_id` FOREIGN KEY (`schedule_id`) REFERENCES `schedules` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlements_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlements_finalized_by` FOREIGN KEY (`finalized_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_settlements_1` CHECK (`status` <> 'FINALIZED' OR (`finalized_by` IS NOT NULL AND `finalized_at` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 정산 지출 항목
CREATE TABLE `settlement_expenses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `settlement_id` BIGINT UNSIGNED NOT NULL,
  `category` VARCHAR(50) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `unit_price_won` BIGINT UNSIGNED NOT NULL,
  `spent_on` DATE NULL,
  `paid_by` BIGINT UNSIGNED NULL,
  `receipt_file_id` BIGINT UNSIGNED NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_settlement_expenses_1` (`settlement_id`),
  KEY `idx_settlement_expenses_2` (`paid_by`),
  KEY `idx_settlement_expenses_3` (`receipt_file_id`),
  CONSTRAINT `fk_settlement_expenses_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `settlements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_expenses_paid_by` FOREIGN KEY (`paid_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_expenses_receipt_file_id` FOREIGN KEY (`receipt_file_id`) REFERENCES `files` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_settlement_expenses_1` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 정산 참가자와 확정 분담액
CREATE TABLE `settlement_participants` (
  `settlement_id` BIGINT UNSIGNED NOT NULL,
  `member_id` BIGINT UNSIGNED NOT NULL,
  `is_exempt` BOOLEAN NOT NULL DEFAULT FALSE,
  `allocated_amount_won` BIGINT UNSIGNED NULL,
  `note` VARCHAR(255) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`settlement_id`, `member_id`),
  KEY `idx_settlement_participants_1` (`member_id`),
  CONSTRAINT `fk_settlement_participants_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `settlements` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_participants_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_settlement_participants_1` CHECK (`is_exempt` IN (0, 1)),
  CONSTRAINT `chk_settlement_participants_2` CHECK (`is_exempt` = 0 OR `allocated_amount_won` IS NULL OR `allocated_amount_won` = 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 이벤트 당첨 발표
CREATE TABLE `giveaways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT NULL,
  `announce_at` DATETIME(6) NOT NULL,
  `status` ENUM('DRAFT','PUBLISHED','CLOSED') NOT NULL DEFAULT 'DRAFT',
  `created_by` BIGINT UNSIGNED NOT NULL,
  `published_by` BIGINT UNSIGNED NULL,
  `published_at` DATETIME(6) NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_giveaways_1` (`status`, `announce_at`),
  KEY `idx_giveaways_2` (`created_by`),
  KEY `idx_giveaways_3` (`published_by`),
  CONSTRAINT `fk_giveaways_created_by` FOREIGN KEY (`created_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_giveaways_published_by` FOREIGN KEY (`published_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `chk_giveaways_1` CHECK (`status` <> 'PUBLISHED' OR (`published_by` IS NOT NULL AND `published_at` IS NOT NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 이벤트 대상 회원과 결과
CREATE TABLE `giveaway_entries` (
  `giveaway_id` BIGINT UNSIGNED NOT NULL,
  `member_id` BIGINT UNSIGNED NOT NULL,
  `result` ENUM('PENDING','WINNER','NOT_WINNER') NOT NULL DEFAULT 'PENDING',
  `updated_by` BIGINT UNSIGNED NOT NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`giveaway_id`, `member_id`),
  KEY `idx_giveaway_entries_1` (`member_id`),
  KEY `idx_giveaway_entries_2` (`updated_by`),
  CONSTRAINT `fk_giveaway_entries_giveaway_id` FOREIGN KEY (`giveaway_id`) REFERENCES `giveaways` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_giveaway_entries_member_id` FOREIGN KEY (`member_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_giveaway_entries_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 중요 운영 작업 기록
CREATE TABLE `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `actor_id` BIGINT UNSIGNED NULL,
  `action` VARCHAR(64) NOT NULL,
  `entity_type` VARCHAR(40) NOT NULL,
  `entity_id` BIGINT UNSIGNED NULL,
  `details` JSON NULL,
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_audit_logs_1` (`entity_type`, `entity_id`, `created_at`),
  KEY `idx_audit_logs_2` (`actor_id`, `created_at`),
  CONSTRAINT `fk_audit_logs_actor_id` FOREIGN KEY (`actor_id`) REFERENCES `members` (`id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `roles` (`code`, `name`) VALUES ('MEMBER', '학회원'), ('STAFF', '운영진'), ('TREASURER', '회계 담당자'), ('ADMIN', '최고 관리자');
