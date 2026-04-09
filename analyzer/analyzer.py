import json
from collections import defaultdict
from datetime import datetime

def analyze_flight_patterns():
    with open("../data/flights.json", encoding="utf-8") as f:
        flights = json.load(f)

    # 시간대별 평균 가격 계산
    hourly_prices = defaultdict(list)
    for flight in flights:
        hour = datetime.fromisoformat(flight["departure_time"]).hour
        hourly_prices[hour].append(flight["price"])

    avg_prices = {hour: sum(prices)/len(prices) for hour, prices in hourly_prices.items()}

    # 결과 저장
    with open("../data/flights_pattern.json", "w", encoding="utf-8") as f:
        json.dump(avg_prices, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    analyze_flight_patterns()
