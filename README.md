# Time-Hacker 프로젝트 구조 및 설명

## 구조

/time-hacker/
├── crawler/           # 데이터 크롤러 (Python)
│   └── flight_crawler.py
├── analyzer/          # 패턴 분석기 (Python)
│   └── analyzer.py
├── data/              # 크롤링/분석 결과 저장 (JSON)
│   └── flights.json
│   └── flights_pattern.json
├── frontend/          # 프론트엔드 (Flutter/React 등)
│   └── main.dart
└── README.md

## 설명
- `crawler/flight_crawler.py`: 항공권 가격 데이터 크롤링 예시 코드
- `analyzer/analyzer.py`: 크롤링된 데이터를 시간대별로 분석하는 코드
- `data/`: 크롤링 및 분석 결과 저장 폴더
- `frontend/main.dart`: Flutter 기반의 간단한 시각화 예시

---

실제 서비스 환경에 맞게 API, 데이터 구조, 프론트엔드 프레임워크 등은 확장/수정 가능합니다.
