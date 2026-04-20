# 구인·구직 API 스펙

기본 prefix: `/api/v1`

## 인증/권한

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `owner`/`manager`만 접근 가능
- 경영주는 본인 점포, 점장은 본인 배정 점포(`branch_id`)만 조회 가능
- 채용 모듈 평점 체계는 현재 **3점 만점** 기준

---

## 0) 채용 공고 이미지 업로드

- `POST /recruitment/files`
- 채용 공고 등록/수정 전에 이미지를 먼저 업로드하고, 반환된 `file_url`을 `profile_image_url`에 넣어 사용

### Request (multipart/form-data)

- `file`: 이미지 파일
- `type`: `posting_profile_image` (고정)

제한:
- 확장자: `png`, `jpg`, `jpeg`, `webp`
- 최대 용량: 10MB

### Response Body (200)

```json
{
  "file_id": "recruitment/posting_profile_image/9c7e02f7f4724e4f9a9c3528a58bc6f1.png",
  "file_url": "https://cdn.example.com/recruitment/posting_profile_image/9c7e02f7f4724e4f9a9c3528a58bc6f1.png",
  "content_type": "image/png",
  "size": 182304
}
```

---

## 1) 채용 홈 조회 (최근 열람 + 구직자 검색)

- `GET /recruitment/branches/{branch_id}/home`
- Figma `채용 홈` 화면의
  - 상단 `최근 열람 구직자`
  - 검색/필터 하단 `구직자 목록`
  을 한번에 반환
- `search_results`는 요청한 `branch_id` 소속 구직자 데이터 기준으로 조회

### Query Params

- `keyword` (optional): 이름/지역/편의점명 검색
- `gender` (optional): `male` | `female` | `all`
- `age_min`, `age_max` (optional)
- `region` (optional): `서울`, `경기`, `부산` 같은 상위 지역 필터. 서버는 지점의 채용공고 `region_summary`, `address`에서 상위 지역을 추출해 매칭
- `min_rating` (optional, 0~3)
- `page` (default=1), `page_size` (default=20)

### Response Body (200)

```json
{
  "recent_viewed_job_seekers": [
    {
      "employee_id": 501,
      "employee_name": "김수민",
      "age": 18,
      "viewed_at": "2026-03-30T12:00:00Z"
    }
  ],
  "search_results": [
    {
      "employee_id": 602,
      "employee_name": "이사라",
      "age": 24,
      "gender": "female",
      "desired_location": "서울 강남구 강남역점",
      "average_rating": 2.7,
      "review_count": 5
    }
  ],
  "total_count": 37,
  "page": 1,
  "page_size": 20
}
```

---

## 2) 구직자 프로필 열람 기록 저장

- `POST /recruitment/branches/{branch_id}/job-seekers/{employee_id}/open`
- 프로필 진입 시 호출
- `최근 열람 구직자` 영역 구성에 사용

### Request Body
없음

### Response Body (200)

```json
{
  "opened": true,
  "employee_id": 602,
  "viewed_at": "2026-03-30T12:02:01Z"
}
```

---

## 3) 구직자 프로필 조회

- `GET /recruitment/branches/{branch_id}/job-seekers/{employee_id}`
- Figma `최근 열람 회원` 상세 화면 데이터

### Request Body
없음

### Response Body (200)

```json
{
  "employee_id": 602,
  "employee_name": "이사라",
  "age": 24,
  "gender": "female",
  "phone_number": "010-1234-5678",
  "career_label": "4년 6개월",
  "desired_locations": ["서울 강남구 개포 2동", "서울 강남구 역삼 1동"],
  "average_rating": 2.7,
  "review_count": 5,
  "work_histories": [
    {
      "period_label": "2024.01 ~ 2025.04",
      "company_name": "(주)나눔 리테일",
      "role_label": "야간스텝"
    }
  ],
  "contact_action_label": "채용 문의하기"
}
```

---

## 3-1) 구직자 채용 문의 등록

- `POST /recruitment/branches/{branch_id}/job-seekers/{employee_id}/contact`
- 구직자 상세 화면의 `채용 문의하기` 액션
- 문의 내용은 관리자 문의함 연동을 위해 서버에 저장됨

### Request Body
```json
{
  "message": "야간 근무 가능 여부 문의드립니다."
}
```

### Response Body (200)
```json
{
  "requested": true,
  "inquiry_id": 120,
  "branch_id": 13,
  "employee_id": 602,
  "employee_name": "이사라",
  "message": "야간 근무 가능 여부 문의드립니다."
}
```

### 비고

- `message`가 비어 오면 서버 기본 문구(`채용 문의를 요청했습니다.`)로 저장

---

## 4) 구직자 리뷰 상세 조회

- `GET /recruitment/branches/{branch_id}/job-seekers/{employee_id}/reviews?page=1&page_size=20`
- Figma `리뷰보기` 화면 데이터
- 리뷰 카드마다 `branch_name`, `manager_name` 포함 (각 지점별 점장 리뷰 식별용)

### Request Body
없음

### Response Body (200)

```json
{
  "employee_id": 602,
  "employee_name": "이사라",
  "desired_location": "서울 강남구 개포 2동",
  "average_rating": 2.7,
  "review_count": 5,
  "items": [
    {
      "review_id": 9001,
      "branch_id": 13,
      "branch_name": "강남역점",
      "manager_name": "홍길동",
      "created_at": "2025-10-10T11:54:21Z",
      "rating": 2,
      "max_rating": 3,
      "comment": "리뷰가 적혀있을 공간입니다."
    }
  ],
  "total_count": 12,
  "page": 1,
  "page_size": 20
}
```

### 비고

- `employee_id`가 음수일 경우(근로자 앱을 통한 외부 지원자) 리뷰 내역이 없으므로 `404` 에러 대신 빈 리뷰 목록(`items: []`, `total_count: 0`)과 평점 0점 형태로 정상 응답(`200`)을 반환합니다.

---

## 5) 채용 게시판 목록 조회

- `GET /recruitment/branches/{branch_id}/postings`
- Figma `채용 게시판` 카드 목록

### Query Params

- `keyword` (optional): 제목/업체명 검색
- `region` (optional): 지역 필터. 서버는 `region_summary`, `address`에서 상위 지역을 추출해 매칭
- `include_draft` (optional, default=false): `true`면 draft 포함
- `page`, `page_size`

### Response Body (200)

```json
{
  "items": [
    {
      "posting_id": 1201,
      "badge_label": "상시모집",
      "company_name": "지에스25 반송행복(업체명)",
      "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
      "region_summary": "해운대구 반송 1동",
      "pay_type": "시급",
      "pay_amount": 10030,
      "applicant_count": 2,
      "applicants_button_label": "지원자 2명",
      "status": "published",
      "created_at": "2026-03-30T12:00:00Z"
    }
  ],
  "total_count": 15,
  "page": 1,
  "page_size": 20
}
```

---

## 6) 내 채용 게시글 목록 조회

- `GET /recruitment/branches/{branch_id}/my-postings?page=1&page_size=20`
- Figma 탭 `내 채용 게시글`

### Response Body (200)
`5) 채용 게시판 목록 조회`와 동일

---

## 7) 채용 공고 상세 조회

- `GET /recruitment/branches/{branch_id}/postings/{posting_id}`
- Figma `채용 게시판 상세` 화면

### Response Body (200)

```json
{
  "posting_id": 1201,
  "profile_image_url": null,
  "badge_label": "상시모집",
  "company_name": "지에스25 반송행복(업체명)",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "region_summary": "해운대구 반송 1동",
  "address": "부산 해운대구 아랫반송로 67-1 (반송동, 미진스토아) 1층",
  "pay_type": "시급",
  "pay_amount": 10030,
  "work_period": "6개월 ~ 1년",
  "work_days": "요일협의",
  "work_days_detail": "(일월 0시-06시/일 06시-11시,월 06시-0시 중 선택)",
  "work_time": "시간협의",
  "work_time_detail": "(일월 0시-06시/일 06시-11시,월 06시-0시 중 선택)",
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
  "status": "published",
  "created_at": "2026-03-30T12:00:00Z",
  "updated_at": "2026-03-30T12:00:00Z"
}
```

---

## 8) 채용 공고 미리보기

- `POST /recruitment/branches/{branch_id}/postings/preview`
- Figma `채용 공고 올리기 > 미리보기` 화면
- DB 저장 없이 본문 그대로 상세 응답 형태로 반환
- **미리보기는 비저장**이며 draft를 만들지 않음

### Request Body
`9) 채용 공고 등록`의 Request와 동일

### Response Body (200)
`7) 채용 공고 상세 조회`와 동일 (`posting_id=0`, `status=preview`)

---

## 9) 채용 공고 등록 (임시저장)

- `POST /recruitment/branches/{branch_id}/postings`
- Figma `채용 공고 올리기`에서 `다음` 후 임시저장(draft)
- `preview` 확인 후 사용자가 저장할 때만 호출

### Request Body

```json
{
  "profile_image_url": "https://cdn.example.com/recruitment/company-1.png",
  "company_name": "지에스25 반송행복(업체명)",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "region_summary": "해운대구 반송 1동",
  "address": "부산 해운대구 아랫반송로 67-1 (반송동, 미진스토아) 1층",
  "pay_type": "시급",
  "pay_amount": 10030,
  "work_period": "6개월 ~ 1년",
  "work_days": "요일협의",
  "work_days_detail": "(일월 0시-06시/일 06시-11시,월 06시-0시 중 선택)",
  "work_time": "시간협의",
  "work_time_detail": "(일월 0시-06시/일 06시-11시,월 06시-0시 중 선택)",
  "job_category": "편의점",
  "employment_type": "알바",
  "recruitment_deadline": "상시모집",
  "is_always_hiring": true,
  "recruitment_headcount": "00명",
  "recruitment_headcount_detail": "(인원 미정)",
  "education": "학력 무관",
  "education_detail": null,
  "manager_name": "이상평",
  "contact_phone": "010-1234-1234"
}
```

### Response Body (200)

```json
{
  "posting_id": 1201,
  "status": "draft",
  "created_at": "2026-03-30T12:00:00Z"
}
```

---

## 10) 채용 공고 게시

- `POST /recruitment/branches/{branch_id}/postings/{posting_id}/publish`
- Figma `미리보기` 화면의 `게시` 버튼

### Response Body (200)

```json
{
  "posting_id": 1201,
  "status": "published",
  "published_at": "2026-03-30T12:10:00Z"
}
```

---

## 11) 지원현황 조회 (공고별)

- `GET /recruitment/branches/{branch_id}/postings/{posting_id}/applications`
- Figma `지원현황` 탭 카드 리스트

### Response Body (200)

```json
{
  "posting_id": 1201,
  "badge_label": "상시모집",
  "company_name": "지에스25 반송행복(업체명)",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "items": [
    {
      "application_id": 3301,
      "applied_date_label": "지원날짜 2026.03.30",
      "employee_id": 602,
      "applicant_user_id": null,
      "application_source": "employee",
      "employee_name": "이사라",
      "desired_location": "서울 강남구 개포 2동",
      "average_rating": 2.7,
      "review_count": 3,
      "resume_title": null
    },
    {
      "application_id": -17,
      "applied_date_label": "지원날짜 2026.03.30",
      "employee_id": null,
      "applicant_user_id": 901,
      "application_source": "worker",
      "employee_name": "김현수",
      "desired_location": "부산 해운대구 반송동",
      "average_rating": 0,
      "review_count": 0,
      "resume_title": "김현수_이력서"
    }
  ],
  "total_count": 2
}
```

### 비고

- 기존 `BranchEmployee` 지원자는 `application_source="employee"`
- 근로자 앱에서 직접 지원한 경우 `application_source="worker"`
- 근로자 앱 지원건은 단일 상세/삭제 라우트를 유지하기 위해 `application_id`가 **음수**로 내려갑니다

---

## 12) 지원자 상세 조회

- `GET /recruitment/branches/{branch_id}/applications/{application_id}`
- Figma `지원현황 상세` 화면
- 응답은 구직자 프로필과 동일 포맷이며 `contact_action_label`이 `삭제`
- 근로자 앱 지원건은 `source_type="worker"`, `applicant_user_id`, `resume_title`이 함께 내려갈 수 있음

### Response Body (200)
`3) 구직자 프로필 조회`와 동일 (단, `contact_action_label="삭제"`)

예: 근로자 앱 지원건

```json
{
  "employee_id": null,
  "applicant_user_id": 901,
  "source_type": "worker",
  "employee_name": "김현수",
  "age": 26,
  "gender": "male",
  "phone_number": "010-1234-5678",
  "career_label": "경력",
  "desired_locations": ["부산 해운대구 반송동"],
  "average_rating": 0,
  "review_count": 0,
  "work_histories": [
    {
      "period_label": "2024.01 ~ 2025.12",
      "company_name": "(주)유통업체",
      "role_label": "재고관리 및 고객응대"
    }
  ],
  "contact_action_label": "삭제",
  "resume_title": "김현수_이력서"
}
```

---

## 13) 지원자 삭제

- `DELETE /recruitment/branches/{branch_id}/applications/{application_id}`
- 지원현황 상세 하단 `삭제` 버튼
- `application_id`는 음수(근로자 앱 지원)도 허용

### Response Body (200)

```json
{
  "deleted": true,
  "application_id": 3301
}
```

---

## 14) 채용 공고 수정

- `PATCH /recruitment/branches/{branch_id}/postings/{posting_id}`
- Figma `내 채용 게시글` 상단 펜 아이콘
- Request는 `9) 채용 공고 등록` 필드 중 변경분만 전달

### Response Body (200)
`7) 채용 공고 상세 조회`와 동일

---

## 15) 채용 공고 삭제

- `DELETE /recruitment/branches/{branch_id}/postings/{posting_id}`
- Figma `내 채용 게시글` 상단 휴지통 아이콘

### Response Body (200)

```json
{
  "deleted": true,
  "posting_id": 1201
}
```

---

## 에러 응답

- `403`: owner/manager 권한 없음 또는 점포 접근 권한 없음
- `404`: 점포 없음 / 구직자 없음 / 공고 없음 / 지원건 없음
