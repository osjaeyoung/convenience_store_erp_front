# 매장 비용 API 스펙

기본 prefix: `/api/v1`

## 인증/권한

- 모든 API는 `Authorization: Bearer {access_token}` 필요
- 경영주(owner): 본인 소유 점포만 접근 가능
- 점장(manager): 본인이 배정된 점포만 접근 가능

---

## 1) 월간 표시 대시보드 조회

- `GET /store-expenses/branches/{branch_id}/dashboard?year=2025&month=9&base_day=10`
- 화면 요구사항 반영:
  - 금일 기준(또는 `base_day`) 월 누적 지출
  - 전달 동기간 대비 상승/하락률
  - 총 점내 비용(해당 월 기준)
  - 카테고리별 요약 카드
  - 달력의 일자별 지출 내역
- `base_day` 생략 시 서버의 오늘 날짜(`today.day`) 기준

### Request Body
없음

### Response Body (200)
```json
{
  "branch_id": 1, // 점포 ID
  "year": 2025, // 조회 연도
  "month": 9, // 조회 월
  "base_day": 10, // 동기간 비교 기준 일자
  "as_of_date": "2025-09-10", // 조회 기준일(YYYY-MM-DD)
  "current_month_to_date_total": 9157430, // 당월 1일~기준일까지 누적 지출(원)
  "previous_month_to_date_total": 8290000, // 전달 동일 구간 누적 지출(원)
  "change_rate_percent": 10.3, // 전달 동기간 대비 증감률(%)
  "monthly_total_cost": 12410000, // 당월 총 점내 비용(현재 집계 기준)
  "category_cards": [
    {
      "category_code": "rent", // 카테고리 코드
      "category_label": "임대료", // 카테고리명
      "month_amount": 3300000, // 당월 카테고리 누적 금액
      "transaction_count": 1 // 건수
    },
    {
      "category_code": "management_fee",
      "category_label": "관리비",
      "month_amount": 1120000,
      "transaction_count": 1
    },
    {
      "category_code": "supplies",
      "category_label": "소모품",
      "month_amount": 102000,
      "transaction_count": 4
    },
    {
      "category_code": "repair",
      "category_label": "수리비",
      "month_amount": 30000,
      "transaction_count": 1
    }
  ],
  "calendar_expenses": [
    {
      "date": "2025-09-10", // 달력 표시 날짜
      "items": [
        {
          "expense_item_id": 501, // 항목 PK
          "category_code": "supplies", // 카테고리 코드
          "category_label": "소모품", // 카테고리명
          "amount": 3800 // 지출 금액(원)
        }
      ],
      "day_total_amount": 3800 // 해당 날짜 총 지출액
    },
    {
      "date": "2025-09-15",
      "items": [
        {
          "expense_item_id": 502,
          "category_code": "repair",
          "category_label": "수리비",
          "amount": 120000
        }
      ],
      "day_total_amount": 120000
    }
  ]
}
```

---

## 2) 월별 점내 비용 묶음(월 카드) 목록 조회

- `GET /store-expenses/branches/{branch_id}/months?year=2025`
- "월별 점내 비용 내역" 탭에서 월 카드 목록 조회
- 각 월 카드에서 `항목 추가` 버튼 노출 가능

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "expense_month_id": 41, // 월 묶음 PK
      "year": 2025, // 연도
      "month": 9, // 월
      "period_label": "2025.09", // 화면 표시용
      "total_amount": 4346000, // 월 합계
      "item_count": 4, // 항목 수
      "created_at": "2025-09-01T09:00:00Z", // 생성 시각
      "updated_at": "2025-09-11T15:20:00Z" // 최종 수정 시각
    },
    {
      "expense_month_id": 42,
      "year": 2025,
      "month": 8,
      "period_label": "2025.08",
      "total_amount": 3892000,
      "item_count": 5,
      "created_at": "2025-08-01T09:00:00Z",
      "updated_at": "2025-08-29T20:11:00Z"
    }
  ]
}
```

---

## 3) 월별 점내 비용 추가 (연도/월 지정)

- `POST /store-expenses/branches/{branch_id}/months`
- "월별 점내 비용 추가" 화면에서 연도/월 선택 후 생성
- 동일 점포+연월은 1건만 허용(중복 생성 방지)

### Request Body
```json
{
  "year": 2025, // 생성할 연도
  "month": 9 // 생성할 월(1~12)
}
```

### Response Body (200)
```json
{
  "expense_month_id": 41, // 생성된 월 묶음 PK
  "year": 2025, // 연도
  "month": 9, // 월
  "period_label": "2025.09", // 화면 표시용
  "total_amount": 0, // 초기 합계
  "item_count": 0, // 초기 항목 수
  "created_at": "2025-09-01T09:00:00Z", // 생성 시각
  "updated_at": "2025-09-01T09:00:00Z" // 수정 시각
}
```

---

## 4) 카테고리 목록 조회 (항목 선택용)

- `GET /store-expenses/categories`
- 항목 추가 화면에서 카테고리 선택 드롭다운 용도

### Request Body
없음

### Response Body (200)
```json
{
  "items": [
    {
      "category_code": "rent", // 카테고리 코드
      "category_label": "임대료", // 화면 표시명
      "is_active": true // 사용 가능 여부
    },
    {
      "category_code": "management_fee",
      "category_label": "관리비",
      "is_active": true
    },
    {
      "category_code": "supplies",
      "category_label": "소모품",
      "is_active": true
    },
    {
      "category_code": "repair",
      "category_label": "수리비",
      "is_active": true
    },
    {
      "category_code": "other",
      "category_label": "기타",
      "is_active": true
    }
  ]
}
```

---

## 5) 항목 추가 (글 데이터만)

- `POST /store-expenses/branches/{branch_id}/months/{expense_month_id}/items`
- 해당 월 카드의 `항목 추가` 버튼으로 진입한 입력 화면 저장
- 파일은 저장하지 않음(파일 저장 API 별도 사용)

### Request Body
```json
{
  "expense_date": "2025-09-11", // 구체 일자
  "category_code": "supplies", // 카테고리 코드
  "amount": 9860, // 금액(원)
  "memo": "테이프/봉투 구매" // 메모(선택)
}
```

### Response Body (200)
```json
{
  "expense_item_id": 501, // 항목 PK
  "expense_month_id": 41, // 월 묶음 PK
  "expense_date": "2025-09-11", // 지출 일자
  "category_code": "supplies", // 카테고리 코드
  "category_label": "소모품", // 카테고리명
  "amount": 9860, // 금액
  "memo": "테이프/봉투 구매", // 메모
  "files": [], // 첨부파일 목록(초기값)
  "created_at": "2025-09-11T09:11:00Z", // 생성 시각
  "updated_at": "2025-09-11T09:11:00Z" // 수정 시각
}
```

---

## 6) 항목 파일 저장 (파일만, 다중 첨부)

- `PATCH /store-expenses/branches/{branch_id}/items/{expense_item_id}/file`
- 영수증/증빙 파일 다중 첨부 가능(append)

### Request Body
```json
{
  "files": [
    {
      "file_key": "expenses/branch-1/2025-09/item-501-receipt.jpg", // S3 key
      "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/expenses/branch-1/2025-09/item-501-receipt.jpg", // S3 URL
      "file_name": "영수증-1.jpg" // 표시용 파일명
    },
    {
      "file_key": "expenses/branch-1/2025-09/item-501-slip.pdf",
      "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/expenses/branch-1/2025-09/item-501-slip.pdf",
      "file_name": "이체내역.pdf"
    }
  ]
}
```

### Response Body (200)
`5) 항목 추가`의 Response와 동일

---

## 7) 월 상세 조회 (해당 월 항목 목록)

- `GET /store-expenses/branches/{branch_id}/months/{expense_month_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "expense_month_id": 41, // 월 묶음 PK
  "year": 2025, // 연도
  "month": 9, // 월
  "period_label": "2025.09", // 화면 표시용
  "total_amount": 4346000, // 월 합계
  "items": [
    {
      "expense_item_id": 501, // 항목 PK
      "expense_date": "2025-09-11", // 구체 일자
      "category_code": "supplies", // 카테고리 코드
      "category_label": "소모품", // 카테고리명
      "amount": 9860, // 금액
      "memo": "테이프/봉투 구매", // 메모
      "files": [
        {
          "file_id": 9001, // 파일 PK
          "file_key": "expenses/branch-1/2025-09/item-501-receipt.jpg", // S3 key
          "file_url": "https://your-bucket.s3.ap-northeast-2.amazonaws.com/expenses/branch-1/2025-09/item-501-receipt.jpg", // URL
          "file_name": "영수증-1.jpg", // 파일명
          "created_at": "2025-09-11T09:15:00Z" // 저장 시각
        }
      ],
      "created_at": "2025-09-11T09:11:00Z", // 생성 시각
      "updated_at": "2025-09-11T09:15:00Z" // 수정 시각
    }
  ],
  "created_at": "2025-09-01T09:00:00Z", // 생성 시각
  "updated_at": "2025-09-11T15:20:00Z" // 수정 시각
}
```

---

## 8) 항목 수정

- `PATCH /store-expenses/branches/{branch_id}/items/{expense_item_id}`

### Request Body
```json
{
  "expense_date": "2025-09-12", // 변경 시 전달
  "category_code": "repair", // 변경 시 전달
  "amount": 120000, // 변경 시 전달
  "memo": "냉장고 손잡이 수리" // 변경 시 전달
}
```

### Response Body (200)
`5) 항목 추가`의 Response와 동일

---

## 9) 항목 삭제

- `DELETE /store-expenses/branches/{branch_id}/items/{expense_item_id}`

### Request Body
없음

### Response Body (200)
```json
{
  "deleted": true // 삭제 성공 여부
}
```

---

## 10) 월 묶음 삭제

- `DELETE /store-expenses/branches/{branch_id}/months/{expense_month_id}`
- 해당 월의 하위 항목/첨부파일까지 함께 삭제

### Request Body
없음

### Response Body (200)
```json
{
  "deleted": true // 삭제 성공 여부
}
```

---

## 구현 규칙(권장)

- 월별 지표 계산:
  - `current_month_to_date_total`: 조회월 1일~`base_day`
  - `previous_month_to_date_total`: 전달 1일~동일 `base_day`(말일 초과 시 말일로 보정)
- 증감률:
  - `previous=0`이고 `current>0`이면 `100.0`
  - `previous=0`이고 `current=0`이면 `0.0`
- 카테고리 코드는 고정 enum으로 시작 후 추후 관리자 설정형으로 확장 가능
- 파일 저장은 기존 정책과 동일하게 `글 저장 API`와 `파일 저장 API`를 분리

---

## 에러 응답

- `400`: 잘못된 `year`/`month`/`base_day` 값
- `400`: 유효하지 않은 `category_code`
- `403`: 점포 접근 권한 없음
- `404`: 점포/월묶음/항목 없음
- `409`: 동일 점포+연월 월묶음 중복 생성
