# 구인·구직 API 스펙

기본 prefix: `/api/v1`

## 인증/권한

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- `owner`/`manager`만 접근 가능
- 경영주는 본인 점포, 점장은 본인 배정 점포(`branch_id`)만 조회 가능
- 채용 모듈 평점 체계는 현재 **3점 만점** 기준

---

## 0) 이미지 업로드

- `POST /recruitment/files`
- 채용 공고 등록/수정 또는 유저 프로필 사진 변경 전에 이미지를 먼저 업로드하고, 반환된 `file_url`을 해당 `profile_image_url`에 넣어 사용

### Request (multipart/form-data)

- `file`: 이미지 파일
- `type`
  - `posting_profile_image`: 채용 공고 대표 이미지
  - `user_profile_image`: 유저 계정 프로필 이미지

제한:
- 확장자: `png`, `jpg`, `jpeg`, `webp`
- 최대 용량: 10MB

### 유저 프로필 사진 저장 흐름

1. `POST /recruitment/files` + `type=user_profile_image`로 이미지 업로드
2. 응답의 `file_url`을 `PATCH /me/account`의 `profile_image_url`로 저장
3. 유저당 프로필 사진은 **1개**이며, 새 URL 저장 시 기존 프로필 사진 URL을 대체합니다.

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
- `search_results`는 기본적으로 **전체 근로자 앱 회원/구직자 풀**을 대상으로 조회합니다. 특정 지점에 이미 등록된 근무자만 노출하면 안 됩니다.
- `branch_id`는 접근 권한, 최근 열람 기록, 리뷰/문의 컨텍스트를 식별하기 위한 값입니다. 검색 대상 범위를 해당 지점 소속 근무자로 제한하는 값이 아닙니다.
- `employee_id`는 프로필 열람/문의/채팅 API에서 사용하는 구직자 식별자입니다. 해당 지점에 이미 등록된 근로자는 실제 `BranchEmployee.id`가 내려오고, 아직 등록 전인 근로자 앱 회원은 `-worker_user_id` 형태의 임시 식별자가 내려옵니다.
- `worker_user_id`는 근로자 앱 회원 계정 ID입니다. 값이 있으면 리뷰 조회는 `worker_user_id` 기준 API를 우선 사용합니다.
- 경영주/점장이 직원관리에서 직접 만든 비회원 근로자(`linked_user_id=null`)는 채용 홈의 최근 열람/검색 목록에 노출하지 않음

### Query Params

- `keyword` (optional): 이름/지역/편의점명 검색
- `gender` (optional): `male` | `female` | `all`
- `age_min`, `age_max` (optional)
- `region` (optional, **다중 선택**): 지역 필터. **OR 조건**. 전달 방식·경로 문자열 규칙·최대 개수·OpenAPI 표기는 하단 **「프론트엔드 연동 가이드 (지역 필터 · 이력서 주소)」** 와 동일. 채용 홈에서는 근로자 이력서의 `resume_region_path`를 최우선으로 매칭하고, 없으면 프로필 주소/희망 근무지 스냅샷 등 서버가 보유한 구직자 위치 텍스트를 fallback으로 사용합니다.
- `min_rating` (optional, 0~3)
- `scope` (optional): `all_workers` 권장. 전체 근로자 앱 회원/구직자 풀에서 검색합니다. 미전달 시에도 서버 기본값은 `all_workers`로 처리합니다. 과거 호환이 필요한 경우에만 서버 내부에서 별도 `branch_workers` 범위를 지원할 수 있습니다.
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
      "worker_user_id": 701,
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

### 식별자 규칙

- 지점에 이미 등록된 근로자: `employee_id=602`, `worker_user_id=901`
- 전체 근로자 앱 회원 풀에서 조회됐지만 아직 현재 지점에 등록되지 않은 근로자: `employee_id=-901`, `worker_user_id=901`
- 프론트는 프로필/문의/채팅에는 `employee_id`를 그대로 사용하고, 리뷰 조회에는 `worker_user_id`가 있으면 `worker_user_id` 기준 API를 사용합니다.

---

## 2) 구직자 프로필 열람 기록 저장

- `POST /recruitment/branches/{branch_id}/job-seekers/{employee_id}/open`
- 프로필 진입 시 호출
- `최근 열람 구직자` 영역 구성에 사용
- `employee_id`는 채용 홈에서 받은 값을 그대로 전달합니다. `employee_id=-{worker_user_id}`인 등록 전 근로자는 서버가 현재 지점의 연결 근무자 row를 생성한 뒤 실제 `employee_id`로 열람 기록을 저장합니다.

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

## 2-1) 구직자 프로필 열람 기록 삭제

- `DELETE /recruitment/branches/{branch_id}/job-seekers/{employee_id}/open`
- `최근 열람 구직자` 목록에서 특정 근로자를 제거할 때 사용

### Request Body
없음

### Response Body (200)

```json
{
  "deleted": true,
  "employee_id": 602
}
```

### 실패 케이스

- 해당 사용자/지점 조합에 저장된 최근 열람 기록이 없으면 `404`

---

## 3) 구직자 프로필 조회

- `GET /recruitment/branches/{branch_id}/job-seekers/{employee_id}`
- Figma `최근 열람 회원` 상세 화면 데이터
- `employee_id`는 채용 홈에서 받은 값을 그대로 전달합니다. `employee_id=-{worker_user_id}`인 등록 전 근로자는 근로자 계정/이력서 기반 프로필을 반환합니다.

### Request Body
없음

### Response Body (200)

```json
{
  "employee_id": 602,
  "worker_user_id": 901,
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
- 대상 구직자가 앱 회원(`worker_user_id` 존재 또는 `linked_user_id` 존재)이면 같은 내용으로 통합 채팅방을 생성/갱신하고 첫 메시지를 저장합니다.
- `employee_id=-{worker_user_id}`인 등록 전 근로자에게 문의하면 서버가 현재 지점의 연결 근무자 row를 생성한 뒤 채팅방을 만듭니다.

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
- **중요 (푸시 알림)**: 대상 구직자가 앱 회원이면 성공 즉시 `type=recruitment_chat`, `entity_type=recruitment_chat`, `entity_id={chat_id}`, `target_route=/job-seeker?tab=3` payload로 푸시/앱 내 알림이 생성됩니다.
- 근로자가 이전에 채팅방을 삭제해 목록에서 숨겨둔 상태라도 새 문의 메시지가 생성되면 근로자 채팅 목록에 다시 표시됩니다.

---

## 4) 구직자 리뷰 상세 조회

- `GET /recruitment/branches/{branch_id}/job-seekers/{employee_id}/reviews?page=1&page_size=20`
- `GET /recruitment/branches/{branch_id}/job-seekers/users/{worker_user_id}/reviews?page=1&page_size=20`
- Figma `리뷰보기` 화면 데이터
- 리뷰 카드마다 `branch_name`, `manager_name` 포함 (각 지점별 점장 리뷰 식별용)
- 등록 전 근로자 앱 회원처럼 아직 현재 지점의 `employee_id`가 없는 대상은 **`worker_user_id` 기준 API**를 사용합니다.
- `worker_user_id` 기준 API는 해당 근로자 계정에 연결된 과거/타 지점 근무자 row의 리뷰를 모아서 반환합니다.

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

- 리뷰 내역이 없으면 `404` 에러 대신 빈 리뷰 목록(`items: []`, `total_count: 0`)과 평점 0점 형태로 정상 응답(`200`)을 반환합니다.
- 전체 근로자 앱 회원 풀에서 내려온 구직자는 현재 지점에 등록 전일 수 있으므로, 프론트는 `worker_user_id`가 있으면 `worker_user_id` 기준 API를 우선 사용합니다. 유효한 `worker_user_id`가 없는 상태에서 `employee_id=-1` 같은 임시값으로 리뷰 API를 호출하지 않습니다.
- `employee_id=-{some_id}`가 실제 근로자 계정이 아닌 과거 호환 값이면 서버는 같은 지점의 `BranchEmployee.id={some_id}`를 fallback으로 찾아 이름과 빈 리뷰 목록을 내려줄 수 있습니다.

---

## 5) 채용 게시판 목록 조회 (전체 공고)

- `GET /recruitment/branches/{branch_id}/postings`
- Figma `채용 게시판` 카드 목록
- **참고:** 경로에 `branch_id`가 포함되어 있으나, 앱 내 전역 채용 게시판 역할을 하므로 `branch_id`와 무관하게 플랫폼 내 **모든 지점의 발행된 채용 공고**를 반환합니다.
- `draft` 공고는 전역 게시판에 공개되지 않습니다. `include_draft=true`를 보낸 경우에도 현재 로그인 사용자가 해당 `branch_id`에서 직접 작성한 임시저장 공고만 함께 내려갑니다.

### Query Params

- `keyword` (optional): 제목/업체명/근무지역 검색
- `region` (optional, **다중 선택**): 지역 필터. **OR**, **최대 5개**, 공백 구분 경로·쉼표·키 반복 규약은 **「프론트엔드 연동 가이드 (지역 필터 · 이력서 주소)」** 참고. 서버는 공고의 `region_path`를 최우선으로 매칭하고, 값이 없는 기존 공고만 `region_summary`, `address` 합성 텍스트와 매칭한다.
- `include_draft` (optional, default=false): `true`면 현재 로그인 사용자의 해당 지점 draft만 추가 포함. 다른 지점/다른 작성자의 draft는 포함되지 않음
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
      "region_summary": "부산 해운대구 반송1동",
      "region_path": "부산 해운대구 반송1동",
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

## 7) 채용 공고 상세 조회 (전체 공고 대상)

- `GET /recruitment/branches/{branch_id}/postings/{posting_id}`
- Figma `채용 게시판 상세` 화면
- **참고:** 발행된 공고는 다른 지점의 공고도 조회할 수 있도록 `branch_id`에 종속되지 않고 `posting_id` 기준으로 상세 정보를 반환합니다.
- `draft` 공고 상세는 현재 로그인 사용자가 해당 `branch_id`에서 직접 작성한 공고일 때만 조회할 수 있습니다. 그 외 draft는 공개 공고가 아니므로 조회 대상이 아니며 `404`로 처리합니다.

### Response Body (200)

```json
{
  "posting_id": 1201,
  "profile_image_url": null,
  "badge_label": "상시모집",
  "company_name": "지에스25 반송행복(업체명)",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "region_summary": "부산 해운대구 반송1동",
  "region_path": "부산 해운대구 반송1동",
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

### 지역 입력 규칙

- 프론트는 공고 작성 화면의 근무지역을 근로자 채용 게시판과 동일한 3단 지역 선택 UI로 입력한다.
- `region_path`는 필수 저장 기준값이며, 앱 지역 트리 라벨을 공백 한 칸으로 이어 붙인다. 예: `서울 강남구 개포2동`, `부산 해운대구 반송1동`.
- `region_summary`는 목록/카드 표시용 문구이며 기본값은 `region_path`와 동일하게 내려준다.
- `address`는 상세주소/도로명 주소 표시용이다. 상세주소가 없으면 서버는 `region_path`를 fallback 표시값으로 사용할 수 있다.
- 기존 클라이언트 호환을 위해 `region_path`가 빠진 요청은 `region_summary`, `address` 순서로 검색 기준값을 보정하지만, 신규 화면은 반드시 근로자 지역 입력과 같은 `region_path`를 보내는 것을 권장한다.

---

## 9) 채용 공고 등록 (임시저장)

- `POST /recruitment/branches/{branch_id}/postings`
- Figma `채용 공고 올리기`에서 `다음` 후 임시저장(draft)
- `preview` 확인 후 사용자가 저장할 때만 호출
- `profile_image_url`은 `POST /recruitment/files` 업로드 결과를 전달합니다. 값을 `null`로 보내면 등록된 업체 프로필 사진을 제거합니다.

### Request Body

```json
{
  "profile_image_url": "https://cdn.example.com/recruitment/company-1.png",
  "company_name": "지에스25 반송행복(업체명)",
  "title": "해운대구 반송 GS편의점 일/월 야간 및 오전 근무",
  "region_summary": "부산 해운대구 반송1동",
  "region_path": "부산 해운대구 반송1동",
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
- 해당 `branch_id`에서 현재 로그인 사용자가 작성한 공고만 게시할 수 있습니다.

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
      "worker_user_id": 901,
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
      "worker_user_id": 901,
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
- `worker_user_id`는 리뷰/채팅 등 사용자 기준 API 호출에 사용합니다. 근로자 앱 직접 지원건은 `applicant_user_id`와 동일한 값이며, 기존 `BranchEmployee` 지원자는 계정 연결이 없으면 `null`일 수 있습니다.
- 근로자 앱 지원건 카드의 `employee_name`은 회원가입 이름 우선, `desired_location`은 이력서 기준 주소 우선으로 내려갑니다

---

## 12) 지원자 상세 조회

- `GET /recruitment/branches/{branch_id}/applications/{application_id}`
- Figma `지원현황 상세` 화면
- 응답은 구직자 프로필과 동일 포맷이며 `contact_action_label`이 `삭제`
- 근로자 앱 지원건은 `source_type="worker"`, `worker_user_id`, `applicant_user_id`, `resume_title`이 함께 내려갈 수 있음
- 근로자 앱 지원건 데이터 우선순위
  - `phone_number`: 회원가입 프로필(`user_profiles.phone_number`) 기준
  - `employee_name`: 회원가입 이름(`users.full_name`) 우선, 없으면 지원 당시 snapshot 이름 fallback
  - `desired_locations`, `career_label`, `work_histories`: 이력서 기준 우선, 없으면 지원 당시 snapshot / 기본값 fallback

### Response Body (200)
`3) 구직자 프로필 조회`와 동일 (단, `contact_action_label="삭제"`)

예: 근로자 앱 지원건

```json
{
  "employee_id": null,
  "worker_user_id": 901,
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

### 비고

- 근로자 앱 지원건의 **희망 근무지** 표시(`desired_location`, `desired_locations`) 우선순위: **지원 시점 스냅샷**(`desired_location_snapshot`) → 그 외 **현재 이력서**의 `resume_region_path`·`resume_address_detail` 합성 → 마지막으로 **프로필** `user_profiles.address`. 스냅샷은 지원 API 호출 시 이력서·프로필 기준으로 서버가 저장하며, 이후 이력서를 고쳐도 지원 카드 문구는 스냅샷을 우선한다.
- 상세 필드·지역 쿼리 규칙은 `docs/api_spec_personal_space.md` 및 하단 **「프론트엔드 연동 가이드」** 참고.
- 근로자 앱 지원건의 `전화번호`는 항상 회원가입 프로필 전화번호 기준으로 내려간다.

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
- 업체 프로필 사진 삭제는 `profile_image_url: null`을 전달합니다.
- 해당 `branch_id`에서 현재 로그인 사용자가 작성한 공고만 수정할 수 있습니다.

### Response Body (200)
`7) 채용 공고 상세 조회`와 동일

---

## 15) 채용 공고 삭제

- `DELETE /recruitment/branches/{branch_id}/postings/{posting_id}`
- Figma `내 채용 게시글` 상단 휴지통 아이콘
- 해당 `branch_id`에서 현재 로그인 사용자가 작성한 공고만 삭제할 수 있습니다.

### Response Body (200)

```json
{
  "deleted": true,
  "posting_id": 1201
}
```

---

## 프론트엔드 연동 가이드 (지역 필터 · 이력서 주소)

개인 공간 이력서(3단 지역 + 상세 주소)와 채용 화면의 지역 필터를 맞출 때 아래를 그대로 따르면 된다. (지역 트리 데이터는 앱의 `korea_region_tree.dart` / `korea_region_other_dongs.dart` 등과 동일한 **라벨 문자열**을 쓰는 것을 권장한다.)

### 적용되는 API

| 용도 | 메서드·경로 | Query `region` |
|------|-------------|----------------|
| 채용 홈 구직자 검색 | `GET /recruitment/branches/{branch_id}/home` | 다중, OR, 최대 5개 |
| 채용 게시판 공고 목록 | `GET /recruitment/branches/{branch_id}/postings` | 동일 |
| 근로자 채용 공고 목록 | `GET /worker/recruitment/postings` | 동일 |

이력서 저장·조회는 `docs/api_spec_personal_space.md`의 `GET/POST/PATCH /worker/resumes` 계열.

---

### 1) `region` 쿼리 — 프론트 규약

- **의미**: 여러 값이 있으면 **OR**(하나라도 매칭되면 해당 공고/카드 포함).
- **한 번에 보낼 수 있는 값의 개수**: **최대 5개**. 6개 이상이면 서버는 **앞에서부터 5개만** 사용한다.
- **여러 값을 넣는 방법** (둘 다 가능):
  - 같은 키 반복: `region=서울&region=경기`
  - 한 파라미터에 쉼표: `region=서울,경기` 또는 `region=서울,경기 수원시 장안구`
- **한 값 안의 공백**: 3단 선택 결과는 **공백으로 이어진 한 경로**다. 예: `서울 강남구 개포2동`, `경기 수원시 장안구`.
- **쉼표**: **값과 값 사이를 나눌 때만** 사용한다. 경로 문자열 **안에는 쉼표를 넣지 않는다**.
- **URL 인코딩**: 공백·한글은 클라이언트에서 `encodeQueryComponent` 등으로 인코딩해 전달한다. (예: `region=%EC%84%9C%EC%9A%B8%20%EA%B0%95%EB%82%A8%EA%B5%AC%20%EA%B0%9C%ED%8F%AC2%EB%8F%99`)
- **OpenAPI / 실제 HTTP**: 채용 홈·채용 게시판·근로자 공고 목록은 모두 쿼리 키 **`region`을 배열로** 받는다 (예: FastAPI에서 `region` 쿼리 반복). 값이 **하나**면 `?region=서울` 한 번이면 된다. **`region`을 아예 보내지 않으면** 지역 조건 없이 전체 후보가 나온다.

**요청 예**

```http
GET /api/v1/worker/recruitment/postings?region=%EC%84%9C%EC%9A%B8%20%EA%B0%95%EB%82%A8%EA%B5%AC&region=%EB%B6%80%EC%82%B0
GET /api/v1/recruitment/branches/1/postings?region=서울,경기 수원시 장안구
GET /api/v1/recruitment/branches/1/home?region=서울&region=부산
```

(스펙 문서·OpenAPI에서는 `region`이 `array of string`으로 보일 수 있다. 위와 같이 **키 반복** 또는 **쉼표로 이은 한 문자열**로 보내도 서버가 동일하게 파싱한다.)

**UI에서 “전체” 동만 선택한 경우**

- 트리에서 동이 `전체`(구 전체)이면, 쿼리에는 **시·도 + 시·군·구까지만** 넣어도 된다. 예: `서울 강남구` (동 토큰 생략). 서버는 공고 텍스트와 **토큰 단위**로 맞추므로 구 단위까지로도 필터 가능하다.

---

### 1-1) 시·도 짧은 라벨 ↔ 서버 별칭 (주소 문구와 맞추기)

앱 지역 트리의 **시·도 라벨**(예: `서울`, `경기`)을 그대로 `region`에 써도 되고, 공고/주소 쪽에 `서울특별시`, `경기도`처럼 긴 표기가 있어도 아래처럼 **같은 광역**으로 매칭된다. (프론트는 `korea_region_tree.dart`의 시·도 문자열과 맞추면 된다.)

| 앱에서 쓰기 좋은 시·도(예시) | 서버가 같은 지역으로 보는 표기 예(비 exhaustive) |
|------------------------------|-----------------------------------------------------|
| 서울 | 서울, 서울시, 서울특별시 |
| 부산 | 부산, 부산시, 부산광역시 |
| 울산 | 울산, 울산시, 울산광역시 |
| 대구 | 대구, 대구시, 대구광역시 |
| 인천 | 인천, 인천시, 인천광역시 |
| 광주 | 광주, 광주시, 광주광역시 |
| 대전 | 대전, 대전시, 대전광역시 |
| 세종 | 세종, 세종시, 세종특별자치시 |
| 경기 | 경기, 경기도 |
| 강원 | 강원, 강원도, 강원특별자치도 |
| 충북 | 충북, 충청북도 |
| 충남 | 충남, 충청남도 |
| 경북 | 경북, 경상북도 |
| 경남 | 경남, 경상남도 |
| 전북 | 전북, 전라북도, 전북특별자치도 |
| 전남 | 전남, 전라남도 |
| 제주 | 제주, 제주시, 제주특별자치도, 제주도 |

시·군·구·동 토큰은 **별칭 테이블 없이** 공고/검색 텍스트에 **부분 문자열로 포함되는지**로 판단한다. 공고 `address`·`region_summary`에 쓰인 표기와 앱 라벨이 다르면(오타 등) 매칭이 안 될 수 있으니, 가능하면 지역 트리와 동일한 동·구 명을 쓰는 것을 권장한다.

---

### 2) 서버 매칭 동작 (프론트가 알면 좋은 것)

**대상 텍스트**

- **채용 공고 목록**(경영주 게시판·근로자 `GET /worker/recruitment/postings`): 공고마다 `region_path`를 최우선으로 사용한다. 기존 데이터처럼 `region_path`가 비어 있으면 `address`와 `region_summary`를 **공백 한 칸으로 이어 붙인 문자열**(앞뒤 공백 정리)을 fallback으로 사용한다.
- **채용 홈**(`GET .../home`): 전체 근로자 앱 회원/구직자 풀을 대상으로, 근로자 이력서의 `resume_region_path`를 최우선 검색 텍스트로 사용한다. 이력서 지역이 없으면 프로필 주소, 희망 근무지 스냅샷 등 서버가 보유한 구직자 위치 텍스트를 fallback으로 사용한다.

**한 개의 `region` 값(한 경로)에 대한 판정 순서**

1. 경로 전체가 위 텍스트에 **부분 문자열로 포함**되면 매칭.
2. 아니면 경로를 **공백으로 분리한 토큰**마다, 텍스트 안에 해당 토큰이 **부분 문자열로 포함**되는지 본다. 시·도 토큰은 위 **별칭 집합** 중 **어느 하나라도** 텍스트에 포함되면 그 토큰은 충족으로 본다.
3. **모든 토큰이** 충족이면 그 경로는 매칭.

**OR**

- 서로 다른 `region` 값(서로 다른 경로)은 **OR**: 경로 A 또는 경로 B 중 하나만 맞아도 결과에 포함된다.

---

### 2-1) `GET /worker/recruitment/postings` 응답의 `region_options`

- **의미**: 현재 **게시 중**인 공고들의 `region_path`에서 뽑아 온 **시·도 수준** 후보 목록(중복 제거·정해진 순으로 정렬). `region_path`가 없는 기존 공고는 `address`·`region_summary`에서 fallback 추출한다.
- **용도**: 빠른 지역 칩·필터 초기 후보 표시 등. **반드시 이 목록만 쿼리에 보내야 하는 것은 아니다.** 3단 트리에서 고른 `서울 강남구 개포2동`처럼 **더 긴 경로**를 `region`에 그대로 넣는 것이 상세 필터에는 적합하다.
- `region_options`에 없는 시·도를 사용자가 고른 경우에도, 위 **별칭·토큰 규칙**만 맞으면 필터는 동작한다.

---

### 3) 이력서 `resume_region_path` · `resume_address_detail`

| 필드 | 의미 | 제약 |
|------|------|------|
| `resume_region_path` | 시·도 / 시·군·구 / 동·읍·면 선택 결과를 **공백 한 칸**으로 이은 문자열 | optional, 최대 **300자** (예: `서울 강남구 개포2동`) |
| `resume_address_detail` | 도로명·동호수 등 **상세 주소** | optional, 최대 **500자** |

- `POST /worker/resumes`, `PATCH /worker/resumes/{resume_id}` 요청 바디에 포함할 수 있다. 생략 가능.
- `GET /worker/resumes/template`, `GET /worker/resumes/{resume_id}` 응답에도 동일하게 내려온다.
- 마이페이지의 `profile_summary.address`(`GET /me/account`)와는 **별도**다. 3단 UI는 이 두 필드에 저장하는 것을 권장한다.

---

### 4) 지원 시 희망 근무지 스냅샷 (경영주/점장 화면)

- 근로자가 `POST /worker/recruitment/postings/{posting_id}/applications`로 지원하면, 서버는 **당시** 이력서의 `resume_region_path`·`resume_address_detail`을 합친 문자열(없으면 프로필 `address`)을 **스냅샷**으로 저장한다.
- 지원현황·지원자 상세의 희망 근무지 문구는 **스냅샷을 최우선**으로 보여 준 뒤, 스냅샷이 비어 있을 때만 현재 이력서·프로필을 참고한다.
- 스냅샷 컬럼 길이 제한으로 **255자를 넘으면 잘린 뒤 `...`이 붙을 수 있다.** UI에서 매우 긴 상세 주소를 넣을 때 참고한다.

---

## 서버/데이터 동작 요약 (참고)

- `region`: **쉼표**로만 여러 값을 나누고, **공백**은 한 값 안의 **경로**를 유지한다. 최대 **5개** 값.
- 이력서 `resume_region_path` / `resume_address_detail`는 DB 컬럼에 저장되며, 지원 API가 희망 근무지 **스냅샷**을 갱신한다.
- 시·도는 위 **별칭 표**에 맞춰 공고·주소의 긴 표기와도 매칭된다.

---

## 에러 응답

- `403`: owner/manager 권한 없음 또는 점포 접근 권한 없음
- `404`: 점포 없음 / 구직자 없음 / 공고 없음 / 지원건 없음

---

## 15) 채용 문의 채팅 방 생성/조회 (경영주/점장 -> 구직자)

- `POST /chats/branches/{branch_id}/employees/{employee_id}`
- 경영주/점장이 특정 구직자/최근 본 근로자에게 문의하기 위해 **지점-근로자 1:1 통합 채팅방**을 생성하거나 기존 방을 조회합니다. (최근 본 근로자 상세화면 등에서 "문의하기" 버튼 클릭 시)
- `employee_id`는 `GET /recruitment/branches/{branch_id}/home` 또는 구직자 프로필 조회에서 받은 전체 구직자 식별자입니다. 서버는 `branch_id` 접근 권한만 검증하고, 대상 근로자가 해당 지점에 이미 등록되어 있는지를 채팅 생성 조건으로 삼으면 안 됩니다.
- 기존 `POST /recruitment/branches/{branch_id}/job-seekers/{employee_id}/inquiry-chats`는 사용하지 않습니다.

### Request Body
없음

### Response Body (200)
```json
{
  "chat_id": 101,
  "branch_id": 1,
  "employee_id": 602,
  "branch_name": "나눔 편의점 강남점",
  "counterparty_name": "이사라",
  "counterparty_role": "worker",
  "counterparty_profile_image_url": "https://cdn.example.com/users/602.png",
  "status": "active",
  "last_message": null,
  "last_message_at": null,
  "unread_count": 0,
  "created_at": "2026-04-24T12:00:00Z"
}
```

### 15-1) 지원현황 상세에서 채팅 방 생성/조회

- `POST /chats/branches/{branch_id}/applications/{application_id}`
- `지원현황 상세` 화면의 `문의하기` 액션
- 근로자 앱에서 지원한 건은 `employee_id`가 없거나 내부 사전등록 근무자 ID와 다를 수 있으므로, 지원건 상세에서는 `application_id` 기준으로 채팅방을 생성/조회합니다.
- 서버는 해당 지원건의 `applicant_user_id` 또는 연결된 근로자 계정을 찾아 같은 지점-근로자 통합 채팅방을 반환합니다.
- 비회원/미연결 지원자처럼 채팅 대상 user가 없는 경우 `404` 대신 `409` 또는 `400`과 함께 사용자 표시용 메시지(`message`)를 내려주는 것을 권장합니다.

### Response Body (200)
`15) 채용 문의 채팅 방 생성/조회`와 동일합니다.

---

## 16) 채용 문의 채팅 목록 조회 (경영주/점장)

- `GET /chats?branch_id={branch_id}`
- 경영주/점장이 해당 지점의 채용 문의/계약 통합 채팅 목록을 조회합니다. (채용 현황의 채팅 내역, 구인·채용의 "채팅" 탭)
- 근로자 앱에서는 `GET /chats`로 본인이 연결된 채팅방 목록을 조회합니다.

### Response Body (200)
```json
{
  "items": [
    {
      "chat_id": 101,
      "branch_id": 1,
      "employee_id": 602,
      "branch_name": "나눔 편의점 강남점",
      "counterparty_name": "이사라",
      "counterparty_role": "worker",
      "counterparty_profile_image_url": "https://cdn.example.com/users/602.png",
      "status": "active",
      "last_message": "지원서 보고 연락드립니다.",
      "last_message_at": "2026-04-24T12:01:00Z",
      "unread_count": 0,
      "created_at": "2026-04-24T12:00:00Z"
    }
  ],
  "total_count": 1
}
```

---

## 17) 채용 문의 채팅 메시지 관련

- `GET /chats/{chat_id}/messages`
- `POST /chats/{chat_id}/messages`
- `PATCH /chats/{chat_id}/read`
- 일반 텍스트 메시지를 전송하면 상대방에게 푸시 알림이 생성/발송됩니다.
- 계약서 전송/작성 완료 이벤트는 같은 채팅방의 `message_type=document` 카드 메시지로 함께 내려옵니다.
- 상대방 또는 발신자가 계정 프로필 이미지를 설정한 경우 `counterparty_profile_image_url`, `sender_profile_image_url`에 표시용 URL이 포함됩니다. 없으면 `null`입니다.
- Flutter 화면은 이 API를 실제 데이터 소스로 사용합니다. 더 이상 채팅 탭/상세에서 mock 메시지를 사용하지 않습니다.
- `current_user_role`은 현재 로그인한 사용자의 말풍선 방향을 결정하는 기준입니다. 경영주/점장 화면에서는 일반적으로 `business`, 근로자 화면에서는 `worker`입니다.
- 상세 화면 진입 직후 `PATCH /chats/{chat_id}/read`를 호출해 현재 로그인 사용자의 미읽음 메시지를 읽음 처리합니다. 서버는 사용자별 `last_read_message_id` 또는 `last_read_at` 커서를 저장해야 하며, 이후 목록 조회의 `unread_count`는 **해당 커서 이후 상대방이 보낸 메시지 수만** 내려줘야 합니다. 이미 읽은 메시지를 누적해서 다시 포함하면 안 됩니다.
- 프론트는 앱 실행 중 실시간성을 위해 채팅 목록은 약 5초, 채팅 상세는 약 3초 간격으로 polling합니다. 서버는 `GET /chats`, `GET /chats/{chat_id}/messages`가 최신 메시지/읽음 상태를 즉시 반영하도록 해야 합니다.
- 향후 WebSocket/SSE를 제공할 경우 `chat_id`, `message_id`, `sender_role`, `message_type`, `text`, `created_at`, `unread_count`를 포함한 이벤트를 현재 REST 응답 구조와 동일하게 내려주면 polling을 대체할 수 있습니다.
- `POST /chats/{chat_id}/messages` 성공 시 상대방이 앱 foreground 상태여도 알림이 표시되도록 FCM 알림을 발송해야 합니다. data-only 푸시를 사용하는 경우에도 `title`/`body` 또는 프론트 fallback 가능한 `type=recruitment_chat`, `entity_type=recruitment_chat`를 포함합니다.

### Foreground Push Payload
```json
{
  "type": "recruitment_chat",
  "target_role": "manager",
  "target_route": "/manager?tab=4&recruitmentTab=3",
  "entity_type": "recruitment_chat",
  "entity_id": "101",
  "branch_id": "1",
  "recruitment_tab": "3",
  "title": "[나눔 편의점 강남점] 새 채팅 메시지",
  "body": "지원서 보고 연락드립니다."
}
```
- 근로자 수신 시 `target_role=worker`, `target_route=/job-seeker?tab=3`로 내려줍니다.
- iOS/Android foreground에서도 표시되도록 FCM `notification.title/body` 또는 data `title/body` 중 하나는 반드시 포함하는 것을 권장합니다.

### Message Send Request
```json
{
  "text": "지원서 보고 연락드립니다."
}
```

### Message Send Response (201)
```json
{
  "message_id": "201",
  "sender_role": "business",
  "sender_name": "김점장",
  "sender_profile_image_url": "https://cdn.example.com/users/manager-1.png",
  "message_type": "text",
  "text": "지원서 보고 연락드립니다.",
  "created_at": "2026-04-24T12:01:00Z",
  "contract_id": null,
  "document_status": null,
  "can_open_document": false,
  "open_document_path": null
}
```

### Mark Read Response (200)
```json
{
  "chat_id": 101,
  "unread_count": 0,
  "read_at": "2026-04-24T12:06:00Z"
}
```

### Message List Response (200)
```json
{
  "chat": {
    "chat_id": 101,
    "branch_id": 1,
    "employee_id": 602,
    "branch_name": "나눔 편의점 강남점",
    "counterparty_name": "이사라",
    "counterparty_role": "worker",
    "counterparty_profile_image_url": "https://cdn.example.com/users/602.png",
    "status": "active",
    "last_message": "지원서 보고 연락드립니다.",
    "last_message_at": "2026-04-24T12:01:00Z",
    "unread_count": 0,
    "created_at": "2026-04-24T12:00:00Z"
  },
  "current_user_role": "business",
  "messages": [
    {
      "message_id": "201",
      "sender_role": "business",
      "sender_name": "김점장",
      "sender_profile_image_url": "https://cdn.example.com/users/manager-1.png",
      "message_type": "text",
      "text": "지원서 보고 연락드립니다.",
      "created_at": "2026-04-24T12:01:00Z",
      "contract_id": null,
      "document_status": null,
      "can_open_document": false,
      "open_document_path": null
    },
    {
      "message_id": "202",
      "sender_role": "business",
      "sender_name": "김점장",
      "sender_profile_image_url": "https://cdn.example.com/users/manager-1.png",
      "message_type": "document",
      "text": "표준 근로 계약 문서",
      "created_at": "2026-04-24T12:02:00Z",
      "contract_id": 901,
      "document_status": "waiting_worker",
      "can_open_document": true,
      "open_document_path": "/api/v1/chats/101/contracts/901/document"
    }
  ]
}
```

### UI 표시 규칙

- `message_type=text`: 일반 말풍선으로 표시합니다.
- `message_type=document`: Figma처럼 흰색 카드 + 그림자 + 밑줄 텍스트로 표시하고, `can_open_document=true`일 때 문서 화면으로 이동합니다.
- 내 메시지 여부는 `messages[].sender_role == current_user_role`로 판단합니다.
- 프로필 이미지는 `counterparty_profile_image_url` 또는 각 메시지의 `sender_profile_image_url`을 우선 사용하고, 값이 없거나 로딩 실패 시 기본 아바타를 표시합니다.

---

## 18) 채용/계약 통합 채팅방 삭제

- `DELETE /chats/{chat_id}`
- 구인·채용의 "채팅" 탭 또는 근로자 개인공간의 "채팅" 목록에서 우측 `more` 아이콘을 눌러 삭제합니다.
- 권한: 해당 채팅방의 경영주/점장 또는 해당 근로자

### Response Body (200)
```json
{
  "deleted": true
}
```

### 비고

- 삭제 후 목록에서 해당 채팅방을 제거합니다.
- 서버 정책에 따라 soft delete로 처리해도 됩니다. 단, 삭제한 사용자에게는 이후 `GET /chats` 목록에 표시되지 않아야 합니다.

