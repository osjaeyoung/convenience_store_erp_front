# 근로자 개인 공간 API

기본 prefix: `/api/v1`

Figma 파일 `개인 공간`에서 현재 반영된 근로자 화면은 아래 10개 노드입니다.

| 노드 ID | 화면명 | 서버 API |
|---------|--------|----------|
| `2534:10928` | 채용정보 | `GET /worker/recruitment/postings` |
| `2534:16920` | 채용 상세 정보 | `GET /worker/recruitment/postings/{posting_id}` |
| `2534:17024` | 지원하기 | `GET /worker/recruitment/postings/{posting_id}/apply-options` |
| `2534:17115` | 지원 확인 모달 | `POST /worker/recruitment/postings/{posting_id}/applications` |
| `2534:17214` | 지원내역 | `GET /worker/recruitment/applications` |
| `2534:17071` | 이력서관리 빈 상태 | `GET /worker/resumes` |
| `2534:17149` | 이력서관리 목록 | `GET /worker/resumes` |
| `2534:17444` | 이력서 작성/수정 | `GET /worker/resumes/template`, `GET /worker/resumes/{resume_id}`, `POST /worker/resumes`, `PATCH /worker/resumes/{resume_id}`, `DELETE /worker/resumes/{resume_id}` |
| `2534:17305` | 마이페이지 | `GET /me/account` |
| `2534:17365` | 회원정보 수정 | `PATCH /me/account` |

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `role=worker` 사용자만 `worker/*` API 호출 가능

---

## 1) GET `/worker/recruitment/postings`

근로자 채용정보 목록.

### Query

- `keyword`: 공고 제목/업체명 검색
- `region`: 지역 필터
- `page`, `page_size`

### Response (200)

```json
{
  "items": [
    {
      "posting_id": 12,
      "branch_id": 3,
      "badge_label": "상시모집",
      "company_name": "지에스25 반송행복",
      "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
      "region_summary": "해운대구 반송 1동",
      "pay_type": "시급",
      "pay_amount": 10030,
      "is_applied": false,
      "applied_at": null,
      "created_at": "2026-03-30T09:00:00Z"
    }
  ],
  "total_count": 24,
  "page": 1,
  "page_size": 20,
  "region_options": [
    "해운대구 반송 1동",
    "수영구 망미동"
  ]
}
```

---

## 2) GET `/worker/recruitment/postings/{posting_id}`

채용 상세 정보.

### Response (200)

```json
{
  "posting_id": 12,
  "branch_id": 3,
  "profile_image_url": null,
  "badge_label": "상시모집",
  "company_name": "지에스25 반송행복",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "region_summary": "해운대구 반송 1동",
  "address": "부산 해운대구 아랫반송로 67-1 1층",
  "pay_type": "시급",
  "pay_amount": 10030,
  "work_period": "6개월 ~ 1년",
  "work_days": "요일협의",
  "work_days_detail": "(일월 0시-06시/ 일 06시-11시,월06시-0시 중 선택)",
  "work_time": "시간협의",
  "work_time_detail": "(일월 0시-06시/ 일 06시-11시,월06시-0시 중 선택)",
  "job_category": "편의점",
  "employment_type": "알바",
  "recruitment_deadline": "상시모집",
  "recruitment_headcount": "00명",
  "recruitment_headcount_detail": "(인원 미정)",
  "education": "학력 무관",
  "education_detail": null,
  "manager_name": "이상평",
  "contact_phone": "010-1234-1234",
  "legal_warning_message": "구직이 아닌 광고 등이 목적으로 연락처를 이용할 경우 법적 처벌을 받을 수 있습니다.",
  "is_applied": false,
  "application_id": null,
  "application_action_label": "지원하기",
  "created_at": "2026-03-30T09:00:00Z",
  "updated_at": "2026-03-30T09:00:00Z"
}
```

---

## 3) GET `/worker/recruitment/postings/{posting_id}/apply-options`

지원하기 화면 진입 시 필요한 데이터.

### Response (200)

```json
{
  "posting_id": 12,
  "company_name": "지에스25 반송행복",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "already_applied": false,
  "existing_application_id": null,
  "can_apply": true,
  "blocked_reason": null,
  "resumes": [
    {
      "resume_id": 7,
      "title": "김현수_이력서",
      "resume_type_label": "이력서",
      "is_default": true,
      "status": "ready",
      "edit_button_label": "수정",
      "delete_button_label": "삭제",
      "can_delete": true,
      "created_at": "2026-03-30T09:00:00Z",
      "updated_at": "2026-03-30T09:00:00Z"
    }
  ],
  "selected_resume_id": 7,
  "confirm_title": "알림",
  "confirm_message": "지원하시겠습니까?"
}
```

### 비고

- 이미 지원한 공고면 `already_applied=true`, `can_apply=false`
- 이력서가 없으면 `blocked_reason="등록된 이력서가 없습니다."`

---

## 4) POST `/worker/recruitment/postings/{posting_id}/applications`

선택한 이력서로 공고 지원.

### Request Body

```json
{
  "resume_id": 7
}
```

### Response (200)

```json
{
  "application_id": 15,
  "posting_id": 12,
  "resume_id": 7,
  "status": "applied",
  "applied_at": "2026-03-30T10:11:12Z"
}
```

### 실패 케이스

- 이미 지원한 공고: `400`
- 본인 이력서 아님 / 없음: `404`
- 지원 불가 상태 이력서: `400`

---

## 5) GET `/worker/recruitment/applications`

내 지원내역 목록.

### Response (200)

```json
{
  "items": [
    {
      "application_id": 15,
      "posting_id": 12,
      "branch_id": 3,
      "badge_label": "상시모집",
      "company_name": "지에스25 반송행복",
      "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
      "region_summary": "해운대구 반송 1동",
      "pay_type": "시급",
      "pay_amount": 10030,
      "applied_at": "2026-03-30T10:11:12Z",
      "applied_date_label": "지원일 2026.03.30"
    }
  ],
  "total_count": 1,
  "page": 1,
  "page_size": 20
}
```

---

## 6) GET `/worker/resumes`

이력서 관리 목록/빈 상태.

### Response (200) 빈 상태

```json
{
  "items": [],
  "total_count": 0,
  "is_empty": true,
  "empty_message": "작성하신 이력서가 없어요.",
  "create_button_label": "이력서 작성"
}
```

### Response (200) 목록 상태

```json
{
  "items": [
    {
      "resume_id": 7,
      "title": "김현수_이력서",
      "resume_type_label": "이력서",
      "is_default": true,
      "status": "ready",
      "edit_button_label": "수정",
      "delete_button_label": "삭제",
      "can_delete": true,
      "created_at": "2026-03-30T09:00:00Z",
      "updated_at": "2026-03-30T09:00:00Z"
    }
  ],
  "total_count": 1,
  "is_empty": false,
  "empty_message": "작성하신 이력서가 없어요.",
  "create_button_label": "이력서 작성"
}
```

### 비고

- `can_delete=false`면 해당 이력서는 이미 지원 이력에 사용 중이라 삭제 불가

---

## 7) GET `/worker/resumes/template`

이력서 신규 작성 템플릿.

### Response (200)

```json
{
  "resume_id": null,
  "resume_title": "김현수_이력서",
  "mode": "create",
  "header_title": "이력서 작성",
  "submit_button_label": "이력서 작성",
  "edit_button_label": "수정",
  "delete_button_label": "삭제",
  "can_delete": false,
  "profile_summary": {
    "full_name": "김현수",
    "gender": "male",
    "gender_label": "남",
    "age": 26,
    "age_label": "만 26세",
    "address": "부산 해운대구 반송동",
    "email": "worker1@test.com",
    "phone_number": "01012345678"
  },
  "education_level": null,
  "education_status": null,
  "career_type": "entry",
  "self_introduction": null,
  "education_level_options": [
    { "value": "high_school", "label": "고등학교" }
  ],
  "education_status_options": [
    { "value": "graduated", "label": "졸업" }
  ],
  "career_type_options": [
    { "value": "entry", "label": "신입" },
    { "value": "experienced", "label": "경력" }
  ],
  "duration_type_options": [
    { "value": "over_one_month", "label": "1개월 이상 근무" },
    { "value": "under_one_month", "label": "1개월 미만 근무" }
  ],
  "career_entries": [],
  "work_history_items": [],
  "add_career_button_label": "경력사항 추가"
}
```

---

## 8) GET `/worker/resumes/{resume_id}`

이력서 상세/수정 화면용 데이터.

### Response (200)

```json
{
  "resume_id": 7,
  "resume_title": "김현수_이력서",
  "mode": "edit",
  "header_title": "이력서 작성",
  "submit_button_label": "수정하기",
  "edit_button_label": "수정",
  "delete_button_label": "삭제",
  "can_delete": true,
  "profile_summary": {
    "full_name": "김현수",
    "gender": "male",
    "gender_label": "남",
    "age": 26,
    "age_label": "만 26세",
    "address": "부산 해운대구 반송동",
    "email": "worker1@test.com",
    "phone_number": "01012345678"
  },
  "education_level": "college_4",
  "education_status": "graduated",
  "career_type": "experienced",
  "self_introduction": "안녕하세요.",
  "career_entries": [
    {
      "career_id": 31,
      "company_name": "(주)나눔 리테일",
      "duration_type": "over_one_month",
      "duration_type_label": "1개월 이상 근무",
      "started_year_month": "2024-01",
      "ended_year_month": "2025-04",
      "duty": "야간스텝",
      "period_label": "2024.01 ~ 2025.04"
    }
  ],
  "work_history_items": [
    {
      "period_label": "2024.01 ~ 2025.04",
      "company_name": "(주)나눔 리테일",
      "duty": "야간스텝"
    }
  ]
}
```

---

## 9) POST `/worker/resumes`

이력서 신규 생성.

### Request Body

```json
{
  "education_level": "college_4",
  "education_status": "graduated",
  "career_type": "experienced",
  "self_introduction": "안녕하세요.",
  "career_entries": [
    {
      "company_name": "(주)나눔 리테일",
      "duration_type": "over_one_month",
      "started_year_month": "2024-01",
      "ended_year_month": "2025-04",
      "duty": "야간스텝"
    }
  ]
}
```

### Response (200)

`8) GET /worker/resumes/{resume_id}`와 동일 스키마.

### 비고

- 제목은 서버가 자동 생성: `홍길동_이력서`, 중복 시 `홍길동_이력서_2`
- 첫 이력서는 자동으로 `is_default=true`

---

## 10) PATCH `/worker/resumes/{resume_id}`

이력서 수정 저장.

### Request Body

`9) POST /worker/resumes`와 동일.

### Response (200)

`8) GET /worker/resumes/{resume_id}`와 동일 스키마.

---

## 11) DELETE `/worker/resumes/{resume_id}`

이력서 삭제.

### Response (200)

```json
{
  "deleted": true,
  "resume_id": 7
}
```

### 실패 케이스

- 이미 지원 이력에 사용된 이력서: `400`

---

## 12) GET `/me/account`

마이페이지/회원정보 수정 진입용.

이번 근로자 화면에서 특히 쓰는 필드:

- `email`
- `full_name`
- `birth_date`, `birth_year`, `birth_month`, `birth_day`
- `gender`
- `phone_number`
- `address`
- `settings_links`
- `has_password_login`

예시는 `docs/api_spec_me_account.md` 참고.

---

## 13) PATCH `/me/account`

회원정보 수정 저장.

### Request Body

```json
{
  "email": "worker1@test.com",
  "full_name": "김현수",
  "birth_year": 1999,
  "birth_month": 3,
  "birth_day": 8,
  "gender": "male",
  "phone_number": "01012345678",
  "address": "부산 해운대구 반송동"
}
```

### Response (200)

`GET /me/account`와 동일 스키마를 반환하며, 이메일이 바뀐 경우:

- `session_refresh_required=true`

프론트는 이메일 변경 후 재로그인 또는 토큰 재발급 플로우를 태워야 합니다.
# 근로자 개인 공간 API

기본 prefix: `/api/v1`

Figma 파일 `개인 공간`에서 이번 구현 범위는 아래 7개 노드입니다.

| 노드 ID | 화면명 | 서버 API |
|---------|--------|----------|
| `2534:10928` | 채용정보 | `GET /worker/recruitment/postings` |
| `2534:16920` | 채용 상세 정보 | `GET /worker/recruitment/postings/{posting_id}` |
| `2534:17024` | 지원하기 | `GET /worker/recruitment/postings/{posting_id}/apply-options` |
| `2534:17115` | 지원 확인 모달 | `POST /worker/recruitment/postings/{posting_id}/applications` |
| `2534:17214` | 지원내역 | `GET /worker/recruitment/applications` |
| `2534:17305` | 마이페이지 | `GET /me/account` |
| `2534:17365` | 회원정보 수정 | `PATCH /me/account` |

## 인증

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `role=worker` 사용자만 `worker/*` API 호출 가능

---

## 1) GET `/worker/recruitment/postings`

근로자 채용정보 목록.

### Query

- `keyword`: 공고 제목/업체명 검색
- `region`: 지역 필터
- `page`, `page_size`

### Response (200)

```json
{
  "items": [
    {
      "posting_id": 12,
      "branch_id": 3,
      "badge_label": "상시모집",
      "company_name": "지에스25 반송행복",
      "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
      "region_summary": "해운대구 반송 1동",
      "pay_type": "시급",
      "pay_amount": 10030,
      "is_applied": false,
      "applied_at": null,
      "created_at": "2026-03-30T09:00:00Z"
    }
  ],
  "total_count": 24,
  "page": 1,
  "page_size": 20,
  "region_options": [
    "해운대구 반송 1동",
    "수영구 망미동"
  ]
}
```

---

## 2) GET `/worker/recruitment/postings/{posting_id}`

채용 상세 정보.

### Response (200)

```json
{
  "posting_id": 12,
  "branch_id": 3,
  "profile_image_url": null,
  "badge_label": "상시모집",
  "company_name": "지에스25 반송행복",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "region_summary": "해운대구 반송 1동",
  "address": "부산 해운대구 아랫반송로 67-1 1층",
  "pay_type": "시급",
  "pay_amount": 10030,
  "work_period": "6개월 ~ 1년",
  "work_days": "요일협의",
  "work_days_detail": "(일월 0시-06시/ 일 06시-11시,월06시-0시 중 선택)",
  "work_time": "시간협의",
  "work_time_detail": "(일월 0시-06시/ 일 06시-11시,월06시-0시 중 선택)",
  "job_category": "편의점",
  "employment_type": "알바",
  "recruitment_deadline": "상시모집",
  "recruitment_headcount": "00명",
  "recruitment_headcount_detail": "(인원 미정)",
  "education": "학력 무관",
  "education_detail": null,
  "manager_name": "이상평",
  "contact_phone": "010-1234-1234",
  "legal_warning_message": "구직이 아닌 광고 등이 목적으로 연락처를 이용할 경우 법적 처벌을 받을 수 있습니다.",
  "is_applied": false,
  "application_id": null,
  "application_action_label": "지원하기",
  "created_at": "2026-03-30T09:00:00Z",
  "updated_at": "2026-03-30T09:00:00Z"
}
```

---

## 3) GET `/worker/recruitment/postings/{posting_id}/apply-options`

지원하기 화면 진입 시 필요한 데이터.

### Response (200)

```json
{
  "posting_id": 12,
  "company_name": "지에스25 반송행복",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "already_applied": false,
  "existing_application_id": null,
  "can_apply": true,
  "blocked_reason": null,
  "resumes": [
    {
      "resume_id": 7,
      "title": "김현수_이력서",
      "resume_type_label": "이력서",
      "is_default": true,
      "status": "ready"
    }
  ],
  "selected_resume_id": 7,
  "confirm_title": "알림",
  "confirm_message": "지원하시겠습니까?"
}
```

### 비고

- 이미 지원한 공고면 `already_applied=true`, `can_apply=false`
- 이력서가 없으면 `blocked_reason="등록된 이력서가 없습니다."`

---

## 4) POST `/worker/recruitment/postings/{posting_id}/applications`

선택한 이력서로 공고 지원.

### Request Body

```json
{
  "resume_id": 7
}
```

### Response (200)

```json
{
  "application_id": 15,
  "posting_id": 12,
  "resume_id": 7,
  "status": "applied",
  "applied_at": "2026-03-30T10:11:12Z"
}
```

### 실패 케이스

- 이미 지원한 공고: `400`
- 본인 이력서 아님 / 없음: `404`
- 지원 불가 상태 이력서: `400`

---

## 5) GET `/worker/recruitment/applications`

내 지원내역 목록.

### Response (200)

```json
{
  "items": [
    {
      "application_id": 15,
      "posting_id": 12,
      "branch_id": 3,
      "badge_label": "상시모집",
      "company_name": "지에스25 반송행복",
      "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
      "region_summary": "해운대구 반송 1동",
      "pay_type": "시급",
      "pay_amount": 10030,
      "applied_at": "2026-03-30T10:11:12Z",
      "applied_date_label": "지원일 2026.03.30"
    }
  ],
  "total_count": 1,
  "page": 1,
  "page_size": 20
}
```

---

## 6) GET `/worker/resumes`

지원하기 화면에서 쓰는 이력서 목록.

### Response (200)

```json
{
  "items": [
    {
      "resume_id": 7,
      "title": "김현수_이력서",
      "resume_type_label": "이력서",
      "is_default": true,
      "status": "ready"
    }
  ],
  "total_count": 1
}
```

---

## 7) GET `/me/account`

마이페이지/회원정보 수정 진입용.

이번 근로자 화면에서 특히 쓰는 필드:

- `email`
- `full_name`
- `birth_date`, `birth_year`, `birth_month`, `birth_day`
- `gender`
- `phone_number`
- `address`
- `settings_links`
- `has_password_login`

예시는 `docs/api_spec_me_account.md` 참고.

---

## 8) PATCH `/me/account`

회원정보 수정 저장.

### Request Body

```json
{
  "email": "worker1@test.com",
  "full_name": "김현수",
  "birth_year": 1999,
  "birth_month": 3,
  "birth_day": 8,
  "gender": "male",
  "phone_number": "01012345678",
  "address": "부산 해운대구 반송동"
}
```

### Response (200)

`GET /me/account`와 동일 스키마를 반환하며, 이메일이 바뀐 경우:

- `session_refresh_required=true`

프론트는 이메일 변경 후 재로그인 또는 토큰 재발급 플로우를 태워야 합니다.
