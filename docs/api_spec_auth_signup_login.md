# 인증/회원가입 API 스펙

기본 prefix: `/api/v1`

## 1) 이메일 회원가입 1차

- `POST /auth/signup` (또는 `/auth/signup/email`)

요청:

```json
{
  "email": "owner@nanum.com",
  "password": "password1234",
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "agree_terms_required": true,
  "agree_age_required": true,
  "agree_privacy_required": true,
  "agree_marketing_optional": false
}
```

응답:

```json
{
  "access_token": "jwt",
  "refresh_token": "jwt",
  "token_type": "bearer",
  "is_new_user": true,
  "user": {
    "id": 1,
    "email": "owner@nanum.com",
    "full_name": "홍길동",
    "phone_number": "01012345678",
    "role": null,
    "signup_step": "step1_completed",
    "approval_status": "pending_role_selection",
    "is_active": true,
    "created_at": "2026-03-05T00:00:00Z",
    "requested_branch_id": null
  }
}
```

## 2) 회원가입 2차 (역할 분기)

- `POST /auth/signup/complete`
- 헤더: `Authorization: Bearer {access_token}`
- 경영주/점장 모두 멀티 지점 등록을 지원합니다.
- 하위 호환을 위해 단건 필드(`branch_name`, `requested_branch_id`, `manager_registration_id`)도 허용할 수 있으나,
  신규 앱은 배열 필드 사용을 권장합니다.

### 2-1) 경영주(사업주)

```json
{
  "role": "owner",
  "branches": [
    {
      "branch_name": "나눔 강남점",
      "business_number": "123-45-67890",
      "owner_name": "홍길동",
      "verification_file_key": "owner-verification/owner-1-gangnam.pdf"
    },
    {
      "branch_name": "나눔 서초점",
      "business_number": "123-45-67890",
      "owner_name": "홍길동",
      "verification_file_key": "owner-verification/owner-1-seocho.pdf"
    }
  ]
}
```

- 전달한 모든 지점이 생성되고 각 지점은 `pending` 심사 상태로 시작합니다.
- 사용자 `approval_status`는 `pending_admin_approval`로 설정됩니다.
- 인증(심사) 결과는 지점 단위로 관리됩니다.

### 2-2) 점장

```json
{
  "role": "manager",
  "requested_branch_ids": [12, 15, 21]
}
```

- 경영주가 오픈한 여러 지점을 선택해 등록 대기할 수 있습니다.
- `approval_status`: `pending_owner_assignment`

또는 경영주가 먼저 점장 사전 등록한 경우(지점별 인증):

```json
{
  "role": "manager",
  "registrations": [
    {
      "manager_registration_id": 101,
      "manager_phone_number": "01033333333"
    },
    {
      "manager_registration_id": 203,
      "manager_phone_number": "01033333333"
    }
  ]
}
```

- 각 항목은 `manager_registration_id` + 전화번호로 본인 인증 후 지점에 연결됩니다.
- 일부 지점만 인증 성공할 수 있으며, 성공 지점은 즉시 `approved_by_owner` 상태로 연결됩니다.
- 실패 지점은 실패 사유와 함께 응답됩니다.

또는 이름+전화번호로 사전 등록된 지점을 한 번에 매칭:

```json
{
  "role": "manager",
  "manager_name": "홍길동",
  "manager_phone_number": "01033333333"
}
```

- 동일 `manager_name` + `manager_phone_number`로 조회된 등록건을 회원가입 완료 시점에 일괄 연결합니다.
- 연결 가능한 지점은 즉시 `approved_by_owner` 처리됩니다.

### 2-3) 근무자(알바생)

```json
{
  "role": "worker"
}
```

- `approval_status`: `pending_manager_assignment`

## 3) 점장 사전등록 지점 조회 (회원가입 단계)

- `POST /auth/signup/manager-registrations/lookup`
- 헤더: `Authorization: Bearer {access_token}`

요청:

```json
{
  "manager_name": "홍길동",
  "manager_phone_number": "01033333333"
}
```

응답:

```json
{
  "items": [
    {
      "registration_id": 101,
      "branch_id": 12,
      "branch_name": "나눔 강남점",
      "branch_code": "AB12CD34",
      "registration_status": "pre_registered",
      "linked_user_id": null
    }
  ]
}
```

## 4) 점장용 지점 검색

- `GET /auth/signup/branches/search?q=강남`

응답:

```json
{
  "items": [
    {
      "id": 12,
      "name": "나눔 강남점",
      "code": "AB12CD34",
      "owner_user_id": 3
    }
  ]
}
```

## 5) 로그인

### 4-1) 이메일 로그인

- `POST /auth/login`

```json
{
  "email": "owner@nanum.com",
  "password": "password1234"
}
```

### 4-2) 구글 로그인

- `POST /auth/login/google`
- Firebase에서 구글 로그인 검증 완료 후 호출

```json
{
  "firebase_uid": "firebase-google-uid",
  "email": "owner@nanum.com",
  "full_name": "홍길동"
}
```

### 4-3) 애플 로그인

- `POST /auth/login/apple`
- Firebase에서 애플 로그인 검증 완료 후 호출

```json
{
  "firebase_uid": "firebase-apple-uid",
  "email": "owner@nanum.com",
  "full_name": "홍길동"
}
```

## 6) 내 정보

- `GET /auth/me`
- 헤더: `Authorization: Bearer {access_token}`

응답에는 역할별로 다중 지점 연결 상태를 포함할 수 있습니다.

```json
{
  "user": {
    "id": 7,
    "email": "manager@nanum.com",
    "role": "manager",
    "signup_step": "step2_completed",
    "approval_status": "approved_by_owner"
  },
  "branches": [
    {
      "branch_id": 12,
      "branch_name": "나눔 강남점",
      "assignment_status": "approved_by_owner"
    },
    {
      "branch_id": 15,
      "branch_name": "나눔 서초점",
      "assignment_status": "pending_owner_assignment"
    }
  ]
}
```

## 7) 토큰 갱신

- `POST /auth/refresh`
- Access Token 만료(기본 1시간) 시 Refresh Token으로 새 토큰 쌍을 발급받습니다.

요청:

```json
{
  "refresh_token": "jwt"
}
```

응답:

```json
{
  "access_token": "jwt",
  "refresh_token": "jwt",
  "token_type": "bearer",
  "is_new_user": false,
  "user": {
    "id": 1,
    "email": "owner@nanum.com",
    "full_name": "홍길동",
    "phone_number": "01012345678",
    "role": "owner",
    "signup_step": "completed",
    "approval_status": "pending_admin_approval",
    "is_active": true,
    "created_at": "2026-03-05T00:00:00Z",
    "requested_branch_id": 31
  }
}
```

## 8) 회원가입 2차 응답 예시 (멀티 지점)

### 8-1) 경영주(owner) 응답

```json
{
  "role": "owner",
  "approval_status": "pending_admin_approval",
  "branches": [
    {
      "branch_id": 31,
      "branch_name": "나눔 강남점",
      "review_status": "pending"
    },
    {
      "branch_id": 32,
      "branch_name": "나눔 서초점",
      "review_status": "pending"
    }
  ]
}
```

### 8-2) 점장(manager) 응답

```json
{
  "role": "manager",
  "approval_status": "pending_owner_assignment",
  "branch_requests": [
    {
      "branch_id": 12,
      "branch_name": "나눔 강남점",
      "assignment_status": "approved_by_owner"
    },
    {
      "branch_id": 15,
      "branch_name": "나눔 서초점",
      "assignment_status": "pending_owner_assignment"
    },
    {
      "branch_id": 21,
      "branch_name": "나눔 홍대점",
      "assignment_status": "rejected_by_owner",
      "reason": "등록 가능한 점장 수 초과"
    }
  ]
}
```

## 소셜 로그인 처리 기준

- 백엔드는 Firebase 검증을 다시 수행하지 않습니다.
- 프론트에서 Firebase 인증 성공 후 전달한 `firebase_uid`를 provider 식별자로 저장합니다.
- provider(`google`/`apple`) + `firebase_uid` 조합으로 계정을 구분합니다.
