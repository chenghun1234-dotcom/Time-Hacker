def crawl_flight_prices():
import json
import os
from datetime import datetime
import pytz
from playwright.sync_api import sync_playwright

# 1. 타겟 설정 (인천 ICN -> 도쿄 NRT, 임의의 날짜)
TARGET_URL = "https://www.google.com/travel/flights?q=Flights%20to%20NRT%20from%20ICN%20on%202026-05-15"
DATA_FILE = "flight_pricing_history.json"

def get_lowest_flight_price():
    """Playwright를 이용해 실시간 최저가 항공권 가격을 스크래핑합니다."""
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        try:
            page.goto(TARGET_URL, timeout=30000)
            page.wait_for_selector(".YMlIz.FpEdX", timeout=15000)
            price_element = page.query_selector(".YMlIz.FpEdX")
            if price_element:
                price_text = price_element.inner_text()
                clean_price = int(price_text.replace('₩', '').replace(',', '').strip())
                return clean_price
            else:
                return None
        except Exception as e:
            print(f"Scraping error: {e}")
            return None
        finally:
            browser.close()

def update_pricing_history(current_price):
    """수집된 가격을 타임스탬프와 함께 JSON 파일에 누적합니다."""
    seoul_tz = pytz.timezone('Asia/Seoul')
    now = datetime.now(seoul_tz)
    day_of_week = now.strftime("%A")
    hour_of_day = now.strftime("%H")
    new_data_point = {
        "timestamp": now.isoformat(),
        "day_of_week": day_of_week,
        "hour_of_day": int(hour_of_day),
        "price_krw": current_price
    }
    history_data = []
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r', encoding='utf-8') as f:
            try:
                history_data = json.load(f)
            except json.JSONDecodeError:
                history_data = []
    history_data.append(new_data_point)
    with open(DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(history_data, f, ensure_ascii=False, indent=4)
    print(f"[{now.strftime('%Y-%m-%d %H:%M:%S')}] 최저가 업데이트 완료: {current_price}원")

if __name__ == "__main__":
    price = get_lowest_flight_price()
    if price:
        update_pricing_history(price)
    else:
        print("가격을 가져오지 못했습니다.")
