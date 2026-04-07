# 계약 채팅 API 명세

## 개요

- 대상 Figma
  - `2534:11025` 계약 채팅 목록
  - `2534:10737` 계약 채팅 상세
  - `2534:10867` 표준 근로계약서 작성/전송
  - `2534:10799` 작성 완료 후 채팅
  - `2534:18788` 완료 문서 조회/다운로드
- 인증: 모든 API는 `Authorization: Bearer <token>` 필요
- 현재 지원 문서: `standard_v1` 표준 근로계약서만 지원

## 사업장 입력 방식 변경사항

- 이번 계약서 UI에서 **점장/경영주와 근로자가 같은 시점에 같은 문서를 완성하지 않습니다.**
- **1단계**: 점장/경영주가 사업장 측 항목만 입력하고 `send_to_worker` 로 전송합니다.
- **2단계**: 근로자가 자기 항목만 입력하고 `complete` 로 완료합니다.
- 따라서 사업장 화면에서는 `worker_address`, `worker_phone`, `worker_signature_text` 를 더 이상 직접 마무리하지 않습니다.
- 문서 조회 응답에서 아래 필드를 기준으로 화면을 제어합니다.
  - `business_field_keys`: 사업장 측 입력 영역
  - `worker_field_keys`: 근로자 입력 영역
  - `editable_field_keys`: 현재 로그인 사용자가 실제로 수정 가능한 필드
  - `required_field_keys`: 현재 단계에서 필수 검증되는 필드

### 사업장(점장/경영주) 화면에서 확인할 핵심 규칙

| 항목 | 변경 후 규칙 |
|------|--------------|
| 문서 생성 | 근로자 검색/연결 후 `POST /contract-chats/branches/{branch_id}/employees/{employee_id}` |
| 임시저장 | `PATCH /contract-chats/{contract_id}/document` + `action=save_draft` |
| 근로자에게 전송 | `PATCH /contract-chats/{contract_id}/document` + `action=send_to_worker` |
| 사업장 입력 범위 | 근무조건, 임금, 사업체 정보, 사업주 서명 |
| 사업장 입력 불가 항목 | 근로자 주소, 근로자 연락처, 근로자 서명 |
| 목록 상태 | 전송 전 `임시저장`, 전송 후 `미완료`, 근로자 완료 후 `작성 완료` |

### 사업장 입력 항목 매핑

| form_values 키 | 한글 라벨 | 사업장 단계 |
|----------------|-----------|-------------|
| `employer_name` | 사업주명 | 필수 |
| `worker_name` | 근로자명 | 필수 |
| `contract_start_date` | 근로개시일 | 필수 |
| `contract_end_date` | 근로종료일 | 선택 |
| `work_place` | 근무 장소 | 필수 |
| `job_description` | 업무 내용 | 필수 |
| `scheduled_work_start_time` | 소정근로 시작 시각 | 필수 |
| `scheduled_work_end_time` | 소정근로 종료 시각 | 필수 |
| `break_start_time` | 휴게 시작 시각 | 선택 |
| `break_end_time` | 휴게 종료 시각 | 선택 |
| `work_days_per_week` | 주당 근무일 수 | 필수 |
| `weekly_holiday_day` | 주휴일 요일 | 필수 |
| `wage_type` | 임금 유형 | 필수 |
| `wage_amount` | 임금 금액 | 필수 |
| `bonus_included` | 상여금 여부 | 선택 |
| `bonus_amount` | 상여금 금액 | 선택 |
| `other_allowance_included` | 기타수당 여부 | 선택 |
| `other_allowance_amount` | 기타수당 총액 | 선택 |
| `meal_allowance` | 식대 | 선택 |
| `transport_allowance` | 교통비 | 선택 |
| `extra_allowance_name` | 기타수당 항목명 | 선택 |
| `extra_allowance_amount` | 기타수당 금액 | 선택 |
| `payment_day` | 임금지급일 | 필수 |
| `payment_method` | 지급방법 | 필수 |
| `annual_leave_note` | 연차유급휴가 문구 | 선택 |
| `contract_delivery_confirmed` | 계약서 교부 확인 | 선택 |
| `law_reference_confirmed` | 근로기준법령 준수 확인 | 선택 |
| `contract_signed_date` | 계약 체결일 | 필수 |
| `employer_business_name` | 사업체명 | 필수 |
| `employer_phone` | 사업장 연락처 | 필수 |
| `employer_address` | 사업장 주소 | 필수 |
| `employer_representative_name` | 대표자 성명 | 필수 |
| `employer_signature_text` | 사업주 서명 | 필수 |

## 플로우

1. 경영주/점장이 기존 근무자 검색/연결 플로우로 근로자를 점포 `employee` 로 연결합니다.
   - 기존 API 재사용:
     - `GET /staff-management/branches/{branch_id}/employees/search-users`
     - `POST /staff-management/branches/{branch_id}/employees/from-user`
2. 경영주/점장이 `POST /contract-chats/branches/{branch_id}/employees/{employee_id}` 로 계약 채팅을 생성합니다.
3. 경영주/점장이 `PATCH /contract-chats/{contract_id}/document` 에서 자기 항목을 저장하고, `action=send_to_worker` 로 전송합니다.
4. 근로자는 `GET /contract-chats` 에서 미완료 계약을 확인하고, 문서를 열어 자기 항목만 입력합니다.
5. 근로자가 `action=complete` 로 완료하면 계약 채팅 상태가 `completed` 로 바뀌고 다운로드가 가능해집니다.

## 상태값

| 값 | 의미 |
|----|------|
| `business_draft` | 사업장 측 임시저장 단계. 아직 근로자에게 보이지 않음 |
| `waiting_worker` | 사업장 측 입력 완료 후 근로자 작성 대기. 목록에서는 `미완료` |
| `completed` | 근로자 작성까지 끝난 상태 |

## 필드 작성 권한

### 사업장(경영주/점장) 입력 필드

- 필수
  - `employer_name`
  - `worker_name`
  - `contract_start_date`
  - `work_place`
  - `job_description`
  - `scheduled_work_start_time`
  - `scheduled_work_end_time`
  - `work_days_per_week`
  - `weekly_holiday_day`
  - `wage_type`
  - `wage_amount`
  - `payment_day`
  - `payment_method`
  - `contract_signed_date`
  - `employer_business_name`
  - `employer_phone`
  - `employer_address`
  - `employer_representative_name`
  - `employer_signature_text`
- 선택
  - `contract_end_date`
  - `break_start_time`
  - `break_end_time`
  - `bonus_included`
  - `bonus_amount`
  - `other_allowance_included`
  - `other_allowance_amount`
  - `meal_allowance`
  - `transport_allowance`
  - `extra_allowance_name`
  - `extra_allowance_amount`
  - `annual_leave_note`
  - `contract_delivery_confirmed`
  - `law_reference_confirmed`

### 근로자 입력 필드

- 필수
  - `worker_address`
  - `worker_phone`
  - `worker_signature_text`

## 1) 계약 채팅 생성

- `POST /contract-chats/branches/{branch_id}/employees/{employee_id}`
- 권한: 경영주/점장
- 비고:
  - `employee.linked_user_id` 가 연결된 근로자만 생성 가능
  - 같은 근무자에 대해 `business_draft`, `waiting_worker` 상태가 이미 있으면 새로 만들 수 없음

### Request Body

```json
{
  "title": "김현수 표준 근로 계약서",
  "template_version": "standard_v1",
  "form_values": {
    "contract_start_date": "2026-04-01",
    "work_place": "서울 강남구 나눔 편의점 강남점",
    "job_description": "계산, 진열, 청소"
  }
}
```

### Response Body (200)

```json
{
  "contract_id": 901,
  "branch_id": 12,
  "employee_id": 88,
  "branch_name": "나눔 편의점 강남점",
  "title": "김현수 표준 근로 계약서",
  "template_version": "standard_v1",
  "chat_status": "business_draft",
  "chat_status_label": "임시저장",
  "current_user_role": "business",
  "business_completion_rate": 26,
  "worker_completion_rate": 0,
  "total_completion_rate": 23,
  "form_values": {
    "employer_name": "나눔 편의점 강남점",
    "employer_business_name": "나눔 편의점 강남점",
    "employer_representative_name": "홍길동",
    "worker_name": "김현수",
    "contract_start_date": "2026-04-01",
    "work_place": "서울 강남구 나눔 편의점 강남점",
    "job_description": "계산, 진열, 청소"
  },
  "document_preview_text": "....",
  "business_field_keys": ["employer_name", "worker_name", "contract_start_date"],
  "worker_field_keys": ["worker_address", "worker_phone", "worker_signature_text"],
  "editable_field_keys": ["employer_name", "worker_name", "contract_start_date"],
  "required_field_keys": ["employer_name", "worker_name", "contract_start_date"],
  "required_field_labels": {
    "employer_name": "사업주명",
    "worker_name": "근로자명",
    "contract_start_date": "근로개시일"
  },
  "primary_action": "send_to_worker",
  "primary_action_label": "전송",
  "download_available": false
}
```

## 2) 계약 채팅 목록 조회

- `GET /contract-chats`
- Query
  - `branch_id` 선택
  - `employee_id` 선택
  - `chat_status` 선택: `business_draft | waiting_worker | completed`
- 권한
  - 경영주/점장: 본인 점포의 계약 채팅 목록
  - 근로자: 본인에게 전송된(`waiting_worker`, `completed`) 계약 채팅 목록

### Response Body (200)

```json
{
  "items": [
    {
      "contract_id": 901,
      "branch_id": 12,
      "employee_id": 88,
      "branch_name": "나눔 편의점 강남점",
      "title": "김현수 표준 근로 계약서",
      "counterparty_name": "홍길동",
      "counterparty_role": "business",
      "chat_status": "waiting_worker",
      "chat_status_label": "미완료",
      "last_message_preview": "김현수 표준 근로 계약서",
      "last_message_at": "2026-04-01T09:30:00Z",
      "unread_count": 1
    }
  ],
  "empty_title": "아직 계약 채팅이 없어요.",
  "empty_description": "점장 또는 경영주가 계약서를 전송하면 이곳에 표시됩니다."
}
```

## 3) 계약 채팅 상세 조회

- `GET /contract-chats/{contract_id}`
- 권한: 해당 점포의 경영주/점장 또는 해당 계약의 근로자
- 비고: 상세 조회 시 상대가 보낸 최신 문서는 읽음 처리됩니다.

### Response Body (200)

```json
{
  "thread": {
    "contract_id": 901,
    "branch_id": 12,
    "employee_id": 88,
    "branch_name": "나눔 편의점 강남점",
    "title": "김현수 표준 근로 계약서",
    "counterparty_name": "홍길동",
    "counterparty_role": "business",
    "chat_status": "completed",
    "chat_status_label": "작성 완료",
    "last_message_preview": "김현수 표준 근로 계약서[작성 완료]",
    "last_message_at": "2026-04-01T10:05:00Z",
    "unread_count": 0
  },
  "current_user_role": "worker",
  "messages": [
    {
      "message_id": "901-business-sent",
      "sender_role": "business",
      "sender_name": "홍길동",
      "message_type": "document",
      "text": "김현수 표준 근로 계약서",
      "created_at": "2026-04-01T09:30:00Z",
      "document_status": "waiting_worker",
      "can_open_document": true,
      "open_document_path": "/api/v1/contract-chats/901/document"
    },
    {
      "message_id": "901-worker-completed",
      "sender_role": "worker",
      "sender_name": "김현수",
      "message_type": "document",
      "text": "김현수 표준 근로 계약서[작성 완료]",
      "created_at": "2026-04-01T10:05:00Z",
      "document_status": "completed",
      "can_open_document": true,
      "open_document_path": "/api/v1/contract-chats/901/document"
    }
  ],
  "can_open_document": true,
  "can_download_document": true
}
```

- 프론트 구현 가이드:
  - `messages[].can_open_document == true` 인 문서 메시지는 말풍선 클릭 시 `messages[].open_document_path`를 호출해 문서 화면으로 이동합니다.
  - 근로자가 `action=complete`를 수행하면 `messages`에 `text="[작성 완료]"` 문구의 문서 메시지가 추가됩니다.

## 3-1) 계약 채팅 삭제

- `DELETE /contract-chats/{contract_id}`
- 권한: 해당 점포 **경영주/점장**, 또는 해당 계약에 연결된 **근로자**(`worker_user_id` 또는 직원 `linked_user_id`가 로그인 사용자와 일치)
- **`chat_status`(임시저장·미완료·작성 완료)와 무관**하게 삭제 가능
- `employment_contract_files` 첨부를 먼저 삭제한 뒤 `employment_contracts` 행을 삭제합니다 (직원관리의 근로계약 삭제와 동일한 정리 방식).

### Response Body (200)

```json
{
  "deleted": true
}
```

## 4) 계약 문서 조회

- `GET /contract-chats/{contract_id}/document`
- 권한: 해당 점포의 경영주/점장 또는 해당 계약의 근로자
- 비고:
  - `business_draft` 에서는 사업장만 볼 수 있음
  - `waiting_worker` 에서는 근로자만 수정 가능
  - `completed` 이후에는 양쪽 모두 읽기 전용

### Response 핵심 필드

- `editable_field_keys`: 현재 사용자가 수정 가능한 필드 목록
- `required_field_keys`: 현재 단계에서 채워야 하는 필드 목록
- `document_preview_text`: 현재 `form_values` 기준 문서 전문 텍스트
- `primary_action`
  - 사업장 초안: `send_to_worker`
  - 근로자 작성 단계: `complete`

## 5) 계약 문서 저장 / 근로자 전송 / 작성 완료

- `PATCH /contract-chats/{contract_id}/document`

### Request Body

```json
{
  "action": "send_to_worker",
  "form_values": {
    "scheduled_work_start_time": "09:00",
    "scheduled_work_end_time": "18:00",
    "work_days_per_week": 5,
    "weekly_holiday_day": "일",
    "wage_type": "hourly",
    "wage_amount": 11000,
    "payment_day": 10,
    "payment_method": "bank_transfer",
    "contract_signed_date": "2026-04-01",
    "employer_phone": "02-1234-5678",
    "employer_address": "서울 강남구 OO로 12",
    "employer_signature_text": "홍길동"
  },
  "merge_form_values": true
}
```

### action 규칙

| action | 권한 | 설명 |
|--------|------|------|
| `save_draft` | 사업장 / 근로자 | 현재 단계에서 자기 필드만 임시저장 |
| `send_to_worker` | 사업장만 | 사업장 필수 항목 검증 후 `waiting_worker` 로 전환 |
| `complete` | 근로자만 | 사업장 필수 + 근로자 필수 검증 후 `completed` 로 전환 |

### 오류 응답 예시 (400)

```json
{
  "detail": {
    "message": "완료 처리할 수 없습니다. 근로자 입력 항목이 누락되었습니다.",
    "missing_fields": [
      "worker_address",
      "worker_signature_text"
    ],
    "missing_fields_labels": {
      "worker_address": "근로자 주소",
      "worker_signature_text": "근로자 서명"
    }
  }
}
```

## 6) 계약 문서 다운로드

- `GET /contract-chats/{contract_id}/download`
- 권한: 해당 점포의 경영주/점장 또는 해당 계약의 근로자
- 조건: `completed` 상태만 가능
- 동작:
  - 계약에 업로드된 대표 파일/PDF가 있으면 그 파일을 스트리밍
  - 업로드 파일이 없으면 현재 `form_values` 로 조합한 UTF-8 `.txt` 문서를 즉시 생성해 다운로드

## 구현 메모

- 기존 `EmploymentContract` 테이블을 재사용하고, 계약 채팅 전용 메타데이터만 추가합니다.
- 기존 `status` 는 최종 완료 시점에만 `completed` 로 바뀌며, 채팅 흐름은 `chat_status` 로 분리합니다.
- 기존 일반 근로계약 API와 분리해, 계약 채팅으로 생성된 문서만 `chat_status != null` 로 관리합니다.
