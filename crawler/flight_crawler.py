import json
import os
from datetime import datetime
import pytz
from playwright.sync_api import sync_playwright

 # 1. 타겟 설정 (인천 ICN -> 도쿄 NRT, 임의의 날짜)
TARGET_URL = "https://www.google.com/travel/flights?q=Flights%20to%20NRT%20from%20ICN%20on%202026-05-15"
# 현재 스크립트 파일 경로 기준으로 데이터 파일 경로 설정
script_dir = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(script_dir, "flight_pricing_history.json")

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
                clean_price = int(price_text.replace('\u20a9', '').replace(',', '').strip())
                return clean_price
            else:
                return None
        except Exception as e:
            print(f"Scraping error: {e}")
            return None
        finally:
            browser.close()


# 메인 실행 블록: 크롤링 결과를 파일에 저장
if __name__ == "__main__":
    price = get_lowest_flight_price()
    if price is not None:
        now = datetime.now(pytz.timezone("Asia/Seoul"))
        record = {
            "timestamp": now.isoformat(),
            "day_of_week": ["월","화","수","목","금","토","일"][now.weekday()],
            "hour_of_day": now.hour,
            "price_krw": price
        }
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, "r", encoding="utf-8") as f:
                try:
                    data = json.load(f)
                except Exception:
                    data = []
        else:
            data = []
        data.append(record)
        with open(DATA_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Saved: {record}")
    else:
        print("Failed to get price.")