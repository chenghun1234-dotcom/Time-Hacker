import 'dart:convert';
import 'package:http/http.dart' as http;

enum PriceStatus { green, red, loading, error }

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
  static const String dataUrl = 'https://[유저명].github.io/[레포지토리명]/flight_pricing_history.json';

  static Future<Map<String, dynamic>> analyzePrice() async {
    try {
      final response = await http.get(Uri.parse(dataUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        if (jsonData.isEmpty) {
          return {'status': PriceStatus.error, 'message': '수집된 데이터가 없습니다.'};
        }
        List<FlightData> history = jsonData.map((item) => FlightData.fromJson(item)).toList();
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        int currentPrice = history.first.priceKrw;
        double total = 0;
        for (var item in history) {
          total += item.priceKrw;
        }
        int averagePrice = (total / history.length).round();
        PriceStatus currentStatus = (currentPrice < averagePrice) ? PriceStatus.green : PriceStatus.red;
        double diffPercent = ((currentPrice - averagePrice) / averagePrice) * 100;
        return {
          'status': currentStatus,
          'currentPrice': currentPrice,
          'averagePrice': averagePrice,
          'diffPercent': diffPercent, 
          'latestUpdate': history.first.timestamp,
          'historyData': history,
        };
      } else {
        return {'status': PriceStatus.error, 'message': '서버 응답 오류: HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': PriceStatus.error, 'message': '네트워크 또는 파싱 오류 발생: $e'};
    }
  }
}
