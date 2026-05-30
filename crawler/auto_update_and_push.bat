@echo off
REM 1. 항공권 가격 크롤링 및 데이터 누적
python flight_crawler.py

REM 2. GitHub에 자동 커밋/푸시
cd /d %~dp0..
git add crawler/flight_pricing_history.json
set dt=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%
git commit -m "auto: update flight price data %dt%"
git push

echo 작업 완료!
pause
