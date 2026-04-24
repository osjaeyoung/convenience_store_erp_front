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

### 서명 필드 (`employer_signature_text`, `worker_signature_text`) — 서버(백엔드) 정책

앱은 서명을 **캔버스에 그린 PNG**를 **Base64 Data URL** 한 줄 문자열로 보냅니다. 필드 이름은 기존과 동일합니다.

| 구분 | 설명 |
|------|------|
| **권장 값 형식** | `data:image/png;base64,<Base64>` |
| **하위 호환** | 짧은 일반 텍스트만 있는 경우(예: `"홍길동"`)도 그대로 허용 |

**백엔드에서 점검·수정 권장 사항**

1. **저장 길이**  
   Data URL은 수 KB~수십 KB 이상이 될 수 있습니다. `form_values`를 JSON 컬럼에 넣거나 별도 컬럼에 둘 때 **문자열 길이 제한(예: VARCHAR(255))** 이면 저장 실패·잘림이 납니다. **`TEXT`/`LONGTEXT` 등으로 확대**하거나, 아래 파일 저장 방식으로 전환하세요.

2. **HTTP 요청 본문 한도**  
   리버스 프록시·API 게이트웨이·프레임워크의 **최대 body 크기**를 계약 저장 API에 맞게 설정하세요.

3. **검증(선택)**  
   - 허용 접두사: `data:image/png;base64,` (필요 시 `image/jpeg` 등만 추가 허용)  
   - 디코드 후 **최대 바이트 수·이미지 크기** 상한으로 남용 방지

4. **저장소(권장)**  
   DB에는 **S3 등 객체 URL** 또는 **파일 ID**만 두고, 실제 PNG는 파일로 저장하는 편이 유리합니다. (키 이름은 유지하고 값만 URL로 바꾸는 방식은 **프론트·서버 합의 후** 별도 필드 도입을 권장합니다.)

5. **문서 텍스트/PDF**  
   평문 미리보기·로그에는 Data URL 전문을 넣지 말고 **`[전자서명]` 등으로 치환**하거나, PDF 생성 시에만 이미지로 임베드하세요.

6. **동일 키를 쓰는 다른 API**  
   직원관리 **근로계약** `form_values` 등 같은 키를 쓰는 엔드포인트는 **동일 정책**을 적용합니다.

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
    "employer_signature_text": "data:image/png;base64,iVBORw0KGgoAAAANS...(생략)"
  },
  "merge_form_values": true
}
```

- `employer_signature_text` / `worker_signature_text`는 위와 같이 **Data URL** 또는 기존처럼 **짧은 문자열** 모두 가능합니다. 서버 요구사항은 본 문서 **「서명 필드 — 서버(백엔드) 정책」** 참고.

### action 규칙

| action | 권한 | 설명 |
|--------|------|------|
| `save_draft` | 사업장 / 근로자 | 현재 단계에서 자기 필드만 임시저장 |
| `send_to_worker` | 사업장만 | 사업장 필수 항목 검증 후 `waiting_worker` 로 전환 |
| `complete` | 근로자만 | 사업장 필수 + 근로자 필수 검증 후 `completed` 로 전환 |

- `form_values`는 프론트가 화면 전체 상태를 통째로 보내도 됩니다.
- 서버는 **현재 단계에서 허용된 키만 반영**하고, 다른 단계의 필드나 UI 전용 임시 필드(예: `work_day_*`)는 **무시**합니다.
- 단, `required_field_keys`에 해당하는 필수값이 비어 있으면 기존처럼 `400`을 반환합니다.
- `action=complete`로 `completed` 전환 시 계약 정보 기준으로 근무현황이 자동 생성됩니다.
  - 같은 계약 유형(`template_version`)의 완료 계약이 여러 건이면 **가장 최근 완료 계약서 기준**으로 반영됩니다.
  - 생성 범위: `contract_start_date` ~ `contract_end_date` (종료일이 없으면 시작일 1일)
  - 생성 시간: `scheduled_work_start_time` ~ `scheduled_work_end_time`
  - 생성 요일: `work_weekdays`/`selected_weekdays`/`work_day_*` 우선, 없으면 `work_days_per_week` + `weekly_holiday_day`로 추론
  - 생성 상태: `scheduled`(예정)
  - 반영 구간의 기존 자동 스케줄(`contract_auto`)은 최신 계약 기준으로 교체됩니다.
  - 이미 수동 스케줄이 있는 날짜는 자동 생성하지 않습니다.

### 프론트엔드 연동 (근무일 자동배정 — `form_values` 요일 맞춤)

계약 완료 시 서버가 `contract_auto` 근무 슬롯을 만들 때 쓰는 요일 해석입니다. **Flutter/Dart와 서버(Python) 요일 번호가 달라** 잘못된 요일에 배정되던 문제를 맞추었으므로, 아래만 지키면 됩니다.

1. **숫자 요일 두 가지 모두 허용 (계약 `form_values` 한정)**  
   - **Dart `DateTime.weekday` / ISO-8601**: `1` = 월요일 … `7` = 일요일 → **권장.** 그대로 보내도 서버가 처리합니다.  
   - **Python `DateTime.weekday`와 동일**: `0` = 월요일 … `6` = 일요일 → 기존처럼 보내도 됩니다.  
   - 적용 필드 예: `weekly_holiday_day`, `work_weekdays` / `selected_weekdays` 배열 안의 숫자 원소.

2. **문자열로 보내는 근무요일**  
   - `work_weekdays`, `selected_weekdays`, `work_days`에 **리스트가 아니라 문자열**이어도 됩니다.  
   - 예: `"월, 화, 수, 목, 금"`, `"월~금"`, `"월/수/금"` (구분자: 쉼표·공백·슬래시·가운뎃점 등).  
   - `월~금`은 월→금 연속 요일로 확장됩니다.

3. **체크박스 키 `work_day_1` … `work_day_7`**  
   - 서버 해석: **`work_day_1` = 월요일**, `work_day_7` = 일요일 (Python weekday 0~6에 대응).  
   - UI에서 요일 순서를 **일요일부터** 쓰는 경우, 체크 인덱스와 위 규칙이 어긋나지 않도록 **전송 전에 요일을 맞게 매핑**하거나, 가능하면 **`work_day_mon` … `work_day_sun`** 형태(명시 키)를 사용하세요.

4. **`PUT /staff-management/branches/{branch_id}/contracts/work-rules` (근무룰 저장)**  
   - 여기의 `weekday`는 **항상 Python 규칙 `0`~`6` (월~일)** 만 사용합니다. Dart `1`~`7`을 그대로 넣지 마세요.  
   - 계약 `form_values`와 근무룰 API를 **같은 화면에서 쓴다면**, 근무룰 API로 넣기 전에 **0~6으로 변환**하세요.

5. **입사일 표시 (직원관리 API)**  
   - DB에 입사일이 비어 있으면 서버가 **`created_at`의 날짜**를 `hire_date` 응답에 채울 수 있습니다. 프론트는 응답 `hire_date`를 그대로 표시하면 됩니다.

---

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
