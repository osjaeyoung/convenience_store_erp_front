# 인증/회원가입 API 스펙

기본 prefix: `/api/v1`

## 0) 이메일 가입 여부 확인

- `GET /auth/email-exists?email={email}`
- **인증 불필요** (회원가입·로그인 전 단계에서 사용)
- Query: `email` (필수, 1~255자)
- 서버는 이메일을 trim 후 소문자로 정규화한 뒤 `users.email`과 비교합니다.

### Response (200)

가입되지 않은 이메일:

```json
{
  "email": "newuser@test.com",
  "exists": false,
  "has_password_login": null,
  "linked_social_providers": []
}
```

이미 가입된 이메일 (예: 애플 로그인으로 `users.email`에 저장된 경우):

```json
{
  "email": "ddkflty0@gmail.com",
  "exists": true,
  "has_password_login": false,
  "linked_social_providers": ["apple"]
}
```

- `exists: true`: 동일 이메일의 `users` 행이 있음 (`POST /auth/signup/email` 시 `400 Email already registered` 와 동일 기준).
- `exists: false`: 해당 이메일로는 아직 사용자 행이 없음 → **이메일·비밀번호 회원가입**을 진행할 수 있음.
- `has_password_login`: `exists: true`일 때만 의미 있음. **소셜 계정만 연결된 경우 `false`** → 이메일/비밀번호 회원가입 화면을 띄우지 말고 **구글/애플 로그인**으로 이어가면 됨. 이메일만으로 가입한 계정(소셜 연동 없음)은 `true`.
- `linked_social_providers`: 해당 계정에 연결된 Firebase 소셜 제공자 목록 (`google`, `apple` 등). 없으면 `[]`.

**애플/구글 가입 플로우:** 소셜 로그인 응답의 `user.email`을 이미 서버에 저장해 두므로, 별도 이메일 입력·`email-exists` 중복 확인 없이 **`POST /auth/signup/social/profile`(선택)** → `POST /auth/signup/complete` 순으로 가면 됩니다. (다만 로그인 전에 “이 이메일로 이미 가입했는지” 안내가 필요하면 `email-exists`를 쓰되, `has_password_login: false`이면 비밀번호 가입으로 유도하지 않습니다.)

### 실패 케이스

- 이메일이 비어 있음(공백만 등): `400`
- 이메일 형식 오류: `400` (`유효한 이메일 형식이 아닙니다.`)

---

## 1) 이메일 회원가입 1차

- `POST /auth/signup` (또는 `/auth/signup/email`)
- **애플·구글 등 소셜만 쓰는 사용자는 이 API를 쓰지 않습니다.** 이메일·비밀번호 없이 `POST /auth/login/google` 또는 `POST /auth/login/apple`로 계정이 만들어진 뒤, 필요 시 아래 **1-1)** 로 약관·전화 등을 넣습니다.

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
    "approval_status": "pending_role_selection",
    "is_active": true,
    "created_at": "2026-03-05T00:00:00Z",
    "requested_branch_id": null
  }
}
```

## 1-1) 소셜 가입 추가 정보 (이메일·비밀번호 없음)

- `POST /auth/signup/social/profile`
- 헤더: `Authorization: Bearer {access_token}` (애플/구글 로그인 직후 받은 토큰)
- **소셜(Firebase)로 `social_accounts`가 연결된 계정만** 호출 가능. 순수 이메일 가입 계정이 호출하면 `400`.
- 이메일은 `POST /auth/login/apple` 등에서 이미 저장되므로 **요청 본문에 넣지 않습니다.** 비밀번호도 없습니다.

요청 예:

```json
{
  "full_name": "홍길동",
  "phone_number": "01012345678",
  "agree_terms_required": true,
  "agree_age_required": true,
  "agree_privacy_required": true,
  "agree_marketing_optional": false
}
```

- `full_name`, `phone_number`는 선택. 보낸 경우 사용자·프로필에 반영합니다.
- 필수 약관 3종은 이메일 1차 회원가입과 동일하게 모두 `true`여야 합니다.

응답: `TokenResponse` (토큰·`user` 갱신, `is_new_user`는 `false`).

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

- 기존 경영주 가입 플로우의 `branch_name`, `business_number`를 그대로 사용합니다.
- 기존 앱 호환을 위해 `owner_name`, `verification_file_key`도 함께 전달할 수 있습니다.
- 단건 호환 필드 사용 시에도 `business_number`를 함께 보내야 합니다.
- 연락처는 1차 회원가입의 `phone_number`를 그대로 사용합니다.
- 전달한 모든 지점이 생성되고 각 지점은 `pending` 심사 상태로 시작합니다.
- 사용자 `approval_status`는 `pending_admin_approval`로 설정됩니다.
- 인증(심사) 결과는 지점 단위로 관리됩니다.

### 2-2) 점장

```json
{
  "role": "manager",
  "manager_name": "홍길동",
  "manager_phone_number": "01033333333"
}
```

- 점장 회원가입은 **사업주가 미리 등록한 `manager_name` + `manager_phone_number` 와, 회원가입 시 사용자 계정에 저장된 `full_name` + `phone_number` 가 일치할 때만 성공**합니다.
- 즉, 프론트가 임의 지점을 골라 `requested_branch_ids` 로 가입시키는 플로우는 더 이상 성공하지 않습니다.
- 매칭된 지점이 있으면 즉시 해당 지점 점장으로 연결되고 `approval_status` 는 `approved_by_owner` 가 됩니다.
- 매칭되는 사전등록 지점이 하나도 없으면 `400`으로 회원가입 완료가 실패합니다.

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

- 각 항목은 `manager_registration_id` 와 **회원가입 시 저장된 이름/전화번호**가 모두 일치해야 지점에 연결됩니다.
- 요청 본문의 `manager_phone_number` 는 하위 호환용이며, 서버는 실제로는 계정에 저장된 `phone_number` 를 기준으로 검증합니다.
- 성공 지점은 즉시 `approved_by_owner` 상태로 연결됩니다.

또는 이름+전화번호로 사전 등록된 지점을 한 번에 매칭:

```json
{
  "role": "manager",
  "manager_name": "홍길동",
  "manager_phone_number": "01033333333"
}
```

- 동일 `manager_name` + `manager_phone_number` 로 조회된 등록건을 회원가입 완료 시점에 일괄 연결합니다.
- 이때도 요청값 자체보다 **회원가입 시 저장된 `full_name` + `phone_number`** 가 최종 기준입니다. 요청값이 저장 정보와 다르면 `400`입니다.
- 연결 가능한 지점은 즉시 `approved_by_owner` 처리됩니다.
- 다른 사람 명의/번호로 사전 등록된 지점을 보내면 회원가입은 실패합니다.

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
- 애플과 동일하게, 로그인 응답에 이메일이 포함되면 **별도 이메일/비밀번호 회원가입 없이** `POST /auth/signup/social/profile`(선택) → `POST /auth/signup/complete` 플로우를 쓸 수 있습니다.

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
- `email`: **선택**. 애플은 재로그인 등에서 이메일을 주지 않는 경우가 있어, 없으면 서버가 `apple-{firebase_uid}@apple-signin.invalid` 형태의 내부용 주소로 사용자를 만듭니다. 클라이언트에서 Firebase `User.email` 등으로 알 수 있으면 보내는 것을 권장합니다.
- **가입 UX:** Firebase에서 내려준 이메일이 있으면 서버가 `users.email`에 저장합니다. 앱은 **이메일 회원가입 단계·`email-exists` 중복 검사 없이** 토큰과 `user.email`만으로 이후 단계(선택 시 `POST /auth/signup/social/profile`, 그다음 `POST /auth/signup/complete`)로 진행하면 됩니다.

```json
{
  "firebase_uid": "firebase-apple-uid",
  "email": "owner@nanum.com",
  "full_name": "홍길동"
}
```

이메일 없이 호출 예:

```json
{
  "firebase_uid": "firebase-apple-uid",
  "full_name": ""
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
