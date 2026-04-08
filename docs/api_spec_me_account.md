# 내 계정 / 개인 공간 API

기본 prefix: `/api/v1`

이 문서는 `me` 라우트 기준의 최신 스펙입니다.  
개인 공간 화면 중 계정 설정, 고객센터, FAQ, 공지사항, 이용약관, 개인정보처리방침 조회 흐름을 포함합니다.

## Figma 화면 매핑

### 계정 / 설정

| 노드 ID | 화면명 | 서버 API |
|---------|--------|----------|
| `2634:16151` | 설정 (메뉴) | `GET /me/account` + 클라이언트 라우팅 |
| `2634:16280` | 내 정보 설정 | `GET /me/account`, `PATCH /me/account` |
| `2634:16329` | 소셜 로그인 계정 설정 | `GET /me/account` |
| `2634:16243` | 비밀번호 변경 | `POST /me/account/password` |
| `2634:16384` | 회원 탈퇴 확인 | `POST /me/account/withdraw` |

### 지원 콘텐츠

| 노드 ID | 화면명 | 서버 API |
|---------|--------|----------|
| `2828:11070` | 고객센터 + FAQ | `GET /me/support-center` |
| `2828:11127` | 이용 정책 목록 | `GET /me/policies` |
| `2828:11038` | 이용약관 보기 | `GET /me/policies/terms` |
| `2828:11206` | 개인정보처리방침 보기 | `GET /me/policies/privacy` |
| `2828:10968` | 공지사항 목록 | `GET /me/notices` |
| `2828:11006` | 공지사항 상세 | `GET /me/notices/{notice_id}` |

## 인증

- 모든 `/me/**` API는 `Authorization: Bearer {access_token}` 필요
- 회원 탈퇴 후 `is_active=false` 가 되면 기존 토큰으로는 더 이상 접근할 수 없습니다

---

## 1) 역할별 내 정보 조회

- `GET /me`

### Response (200)

```json
{
  "id": 2,
  "email": "worker1@test.com",
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "role": "worker",
  "approval_status": "approved_by_owner",
  "is_active": true,
  "created_at": "2026-01-01T00:00:00Z",
  "owner": null,
  "manager": null,
  "worker": {
    "requested_branch_id": 3
  }
}
```

### 비고

- 역할에 따라 `owner`, `manager`, `worker` 중 하나만 채워집니다
- 홈/대시보드 진입용 요약 응답입니다

---

## 2) 내 계정 정보 조회

- `GET /me/account`

### Response (200)

```json
{
  "user_id": 2,
  "email": "worker1@test.com",
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "phone_number_masked": "010-****-5678",
  "role": "worker",
  "role_label_ko": "근무자",
  "usage_type_label_ko": "근무자",
  "approval_status": "approved_by_owner",
  "approval_status_label_ko": "점주 승인 완료",
  "is_active": true,
  "member_since": "2026-01-01T00:00:00Z",
  "birth_date": "1999-03-08",
  "birth_year": 1999,
  "birth_month": 3,
  "birth_day": 8,
  "gender": "male",
  "address": "부산 해운대구 반송동",
  "branches": [],
  "settings_links": {
    "support_url": null,
    "notices_url": null,
    "policy_url": null
  },
  "has_password_login": true,
  "session_refresh_required": false
}
```

### 주요 필드

- `role_label_ko`: 역할 한글 라벨
- `usage_type_label_ko`: 설정 화면 표시용 라벨
- `settings_links`: 외부 링크 하위 호환용
- `has_password_login`: 비밀번호 변경 행 노출 여부 힌트
- `session_refresh_required`: 이메일 변경 직후 재로그인/토큰 재발급 필요 여부

---

## 3) 내 계정 정보 수정

- `PATCH /me/account`

### Request Body

보낸 필드만 수정합니다.

```json
{
  "email": "worker1@test.com",
  "full_name": "홍길동",
  "birth_year": 1999,
  "birth_month": 3,
  "birth_day": 8,
  "gender": "male",
  "phone_number": "01012345678",
  "address": "부산 해운대구 반송동"
}
```

### Response (200)

`GET /me/account` 와 동일 스키마

### 비고

- 이메일이 변경되면 `session_refresh_required=true`
- 이메일 중복이면 `400`
- **회원가입 전** 이메일 중복 여부만 확인할 때는 `GET /auth/email-exists?email=...` 를 사용합니다. (`PATCH /me/account` 는 로그인 후 계정 수정용입니다.)
- 생년월일은 연/월/일을 모두 보내야 하며 잘못된 날짜면 `400`

---

## 4) 비밀번호 변경

- `POST /me/account/password`

### Request Body

```json
{
  "current_password": "기존비밀번호",
  "new_password": "새비밀번호8자이상"
}
```

### Response (200)

```json
{
  "updated": true,
  "message": "비밀번호가 변경되었습니다."
}
```

### 실패 케이스

- 현재 비밀번호 불일치: `400`
- 새 비밀번호가 기존 비밀번호와 동일: `400`

---

## 5) 회원 탈퇴

- `POST /me/account/withdraw`

### Request Body

```json
{
  "confirm": true
}
```

### Response (200)

```json
{
  "withdrawn": true,
  "message": "탈퇴 처리되었습니다. 이용해 주셔서 감사합니다."
}
```

---

## 6) 고객센터 정보 조회

- `GET /me/support-center`

### Response (200)

```json
{
  "support_email": "support@example.com",
  "support_email_label": "고객센터",
  "faqs": [
    {
      "faq_id": 2,
      "question": "비밀번호를 잊었어요.",
      "answer": "전화번호 인증 후 재설정해 주세요.",
      "sort_order": 0
    },
    {
      "faq_id": 1,
      "question": "예약은 어떻게 하나요?",
      "answer": "앱에서 예약 버튼을 눌러 진행합니다.",
      "sort_order": 1
    }
  ]
}
```

### 비고

- `support_email` 이 아직 설정되지 않았으면 `null`
- `faqs` 는 `is_visible=true` 인 항목만 반환합니다
- 정렬은 `sort_order ASC`, 동일 순서는 `updated_at DESC`, `faq_id ASC`

---

## 7) 이용정책 목록 조회

- `GET /me/policies`

### Response (200)

```json
{
  "items": [
    {
      "policy_type": "terms",
      "title": "이용약관",
      "updated_at": "2026-04-07T12:05:00Z",
      "is_configured": true
    },
    {
      "policy_type": "privacy",
      "title": "개인정보처리방침",
      "updated_at": "2026-04-07T12:06:00Z",
      "is_configured": true
    }
  ]
}
```

### 비고

- 고정 정책 타입은 `terms`, `privacy`
- 아직 문서가 저장되지 않은 경우 `is_configured=false`, `updated_at=null`

---

## 8) 이용정책 상세 조회

- `GET /me/policies/{policy_type}`

### Path

- `policy_type`: `terms` | `privacy`

### Response (200)

```json
{
  "policy_type": "terms",
  "title": "이용약관",
  "content": "약관 내용입니다.",
  "updated_at": "2026-04-07T12:05:00Z"
}
```

### 실패 케이스

- 문서가 아직 설정되지 않았으면 `404`

---

## 9) 공지사항 목록 조회

- `GET /me/notices`

### Query

- `page` (default=1, >=1)
- `page_size` (default=20, 1~100)

### Response (200)

```json
{
  "items": [
    {
      "notice_id": 101,
      "title": "서비스 점검 안내",
      "content": "2026년 4월 10일 02:00~04:00 동안 점검이 진행됩니다.",
      "published_at": "2026-04-05T09:00:00Z"
    }
  ],
  "total_count": 1,
  "page": 1,
  "page_size": 20
}
```

### 비고

- Figma 목록 화면에서는 주로 `title`, `published_at` 을 사용하면 됩니다
- 서버 응답에는 `content` 도 함께 포함됩니다

---

## 10) 공지사항 상세 조회

- `GET /me/notices/{notice_id}`

### Response (200)

```json
{
  "notice_id": 101,
  "title": "서비스 점검 안내",
  "content": "2026년 4월 10일 02:00~04:00 동안 점검이 진행됩니다.",
  "published_at": "2026-04-05T09:00:00Z"
}
```

### 실패 케이스

- 없는 `notice_id`: `404`

---

## 11) 문의 등록

- `POST /me/inquiries`

### Request Body

```json
{
  "inquiry_type": "account",
  "title": "로그인이 안 돼요",
  "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다."
}
```

### 허용 `inquiry_type`

- `account`
- `service`
- `recruitment`
- `payment`
- `etc`

### Response (201)

```json
{
  "inquiry_id": 501,
  "inquiry_type": "account",
  "title": "로그인이 안 돼요",
  "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다.",
  "created_at": "2026-04-05T10:30:00Z",
  "is_answered": false,
  "is_answer_checked": false,
  "answer": null,
  "answered_at": null
}
```

---

## 12) 내 문의 목록 조회

- `GET /me/inquiries`

### Query

- `page` (default=1, >=1)
- `page_size` (default=20, 1~100)

### Response (200)

```json
{
  "items": [
    {
      "inquiry_id": 501,
      "inquiry_type": "account",
      "title": "로그인이 안 돼요",
      "content": "전화번호 인증은 끝났는데 로그인 단계에서 막힙니다.",
      "created_at": "2026-04-05T10:30:00Z",
      "is_answered": true,
      "is_answer_checked": false,
      "answer": "앱을 최신 버전으로 업데이트한 뒤 다시 시도해 주세요.",
      "answered_at": "2026-04-05T11:00:00Z"
    }
  ],
  "total_count": 1,
  "page": 1,
  "page_size": 20
}
```

---

## 13) 내 문의 상세 조회

- `GET /me/inquiries/{inquiry_id}`

### Response (200)

문의 목록 아이템과 동일

### 실패 케이스

- 본인 문의가 아니거나 없으면 `404`

---

## 14) 문의 답변 확인 처리

- `POST /me/inquiries/{inquiry_id}/answer-check`

### Request Body

없음

### Response (200)

```json
{
  "inquiry_id": 501,
  "is_answer_checked": true,
  "checked_at": "2026-04-05T11:05:00Z"
}
```

### 실패 케이스

- 답변이 아직 없으면 `400`
- 본인 문의가 아니거나 없으면 `404`

---

## 하위 호환 메모

- `settings_links.support_url`, `settings_links.notices_url`, `settings_links.policy_url` 는 기존 외부 링크 방식 하위 호환용입니다
- 이번 지원 콘텐츠 플로우는 `GET /me/support-center`, `GET /me/policies`, `GET /me/notices` 같은 in-app 조회 API 사용을 권장합니다

---

## 에러 응답

- `400`: 비밀번호 검증 실패, 잘못된 생년월일, 아직 답변 없음 등
- `401`: 인증 안 됨
- `404`: 공지 / 문의 / 정책 문서 없음
- `422`: FastAPI / Pydantic 입력 검증 실패
