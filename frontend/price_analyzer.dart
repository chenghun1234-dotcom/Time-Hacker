import 'dart:convert';
import 'package:http/http.dart' as http;

// 1. 상태를 명확히 구분하는 Enum (UI에서 신호등 색상을 결정할 때 사용)
enum PriceStatus { green, red, loading, error }

// 2. JSON 데이터를 담을 모델 클래스
class FlightData {
  final DateTime timestamp;
  final String dayOfWeek;
  final int hourOfDay;
  final int priceKrw;

  FlightData({
    required this.timestamp,
    required this.dayOfWeek,
    required this.hourOfDay,
    required this.priceKrw,
  });

  // JSON Map을 Dart 객체로 변환하는 팩토리 생성자
  factory FlightData.fromJson(Map<String, dynamic> json) {
    return FlightData(
      timestamp: DateTime.parse(json['timestamp']),
      dayOfWeek: json['day_of_week'],
      hourOfDay: json['hour_of_day'],
      priceKrw: json['price_krw'],
    );
  }
}

class PriceAnalyzer {
  // 💡 Phase 2에서 확보한 본인의 GitHub Pages JSON URL을 입력하세요.
  static const String dataUrl = 'https://[유저명].github.io/[레포지토리명]/flight_pricing_history.json';

  // 핵심 로직: 데이터를 가져와 분석 후 Map 형태로 UI에 반환
  static Future<Map<String, dynamic>> analyzePrice() async {
    try {
      // HTTP GET 요청
      final response = await http.get(Uri.parse(dataUrl));

      if (response.statusCode == 200) {
        // 1. JSON 디코딩
        List<dynamic> jsonData = json.decode(response.body);

        if (jsonData.isEmpty) {
          return {'status': PriceStatus.error, 'message': '수집된 데이터가 없습니다.'};
        }

        // 2. 객체 리스트로 매핑
        List<FlightData> history = jsonData.map((item) => FlightData.fromJson(item)).toList();

        // 3. 최신 날짜순 정렬 (가장 첫 번째 인덱스가 방금 수집된 최신 가격)
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        // 4. 현재가 추출
        int currentPrice = history.first.priceKrw;

        // 5. 평균가 계산 (전체 누적 데이터 기준)
        double total = 0;
        for (var item in history) {
          total += item.priceKrw;
        }
        int averagePrice = (total / history.length).round();

        // 6. 상태 판별 (현재가가 평균가보다 낮으면 GREEN, 높거나 같으면 RED)
        PriceStatus currentStatus = (currentPrice < averagePrice) ? PriceStatus.green : PriceStatus.red;

        // 7. 차액 퍼센트 계산 (예: -15.2% 또는 +5.0%)
        double diffPercent = ((currentPrice - averagePrice) / averagePrice) * 100;

        // UI에서 즉시 사용할 수 있도록 가공된 데이터를 반환
        return {
          'status': currentStatus,
          'currentPrice': currentPrice,
          'averagePrice': averagePrice,
          'diffPercent': diffPercent, 
          'latestUpdate': history.first.timestamp,
          'historyData': history, // 차트를 그리기 위해 전체 데이터도 같이 넘겨줌
        };

      } else {
        return {'status': PriceStatus.error, 'message': '서버 응답 오류: HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': PriceStatus.error, 'message': '네트워크 또는 파싱 오류 발생: $e'};
    }
  }
}
