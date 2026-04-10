// This file has been removed as per the patch request.
// All previous code and functionality have been deleted.
// Please refer to the version control system for the last stable version.

    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final currencyFormat = NumberFormat('#,###', 'en_US');
  Timer? _timer;
  Duration countdown = Duration.zero;
  int nextHour = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(int minHour) {
    _timer?.cancel();
    final now = DateTime.now();
    int nowMinutes = now.hour * 60 + now.minute;
    int targetMinutes = minHour * 60;
    int diff = targetMinutes - nowMinutes;
    if (diff < 0) diff += 24 * 60;
    setState(() {
      countdown = Duration(minutes: diff);
      nextHour = minHour;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (countdown.inSeconds > 0) {
          countdown -= const Duration(seconds: 1);
        }
      });
    });
  }

  Future<void> _launchAffiliateLink() async {
    final Uri url = Uri.parse('https://app.trip.com/광고코드/인천-도쿄');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('링크를 열 수 없습니다: $url');
    }
  }

  Widget _buildCountdownTimer() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(countdown.inHours);
    final m = twoDigits(countdown.inMinutes.remainder(60));
    final s = twoDigits(countdown.inSeconds.remainder(60));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text('다음 덤핑까지 $h:$m:$s 남음 (예상 $nextHour시)', style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }

  Widget _buildLineChart(List<dynamic> history) {
    final now = DateTime.now();
    final today = history.where((e) {
      final t = DateTime.parse(e['timestamp']);
      return t.year == now.year && t.month == now.month && t.day == now.day;
    }).toList();
    Map<int, int> hourPrice = {};
    for (var e in today) {
      final t = DateTime.parse(e['timestamp']);
      final h = t.hour;
      if (!hourPrice.containsKey(h) || hourPrice[h]! > e['price_krw']) {
        hourPrice[h] = e['price_krw'];
      }
    }
    final spots = hourPrice.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    if (spots.isEmpty) return const Center(child: Text('오늘 데이터 부족', style: TextStyle(color: Colors.white70)));
    final minSpot = spots.reduce((a, b) => a.y < b.y ? a : b);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 23,
        minY: spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95,
        maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05,
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
            return value % 3 == 0 ? Text('${value.toInt()}시', style: const TextStyle(fontSize: 12, color: Colors.white70)) : const SizedBox.shrink();
          })),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(enabled: true),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: minSpot.y,
            color: Colors.green,
            strokeWidth: 2,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.centerRight,
              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
              labelResolver: (_) => '최저가 ${minSpot.y.toInt()}원',
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('✈️ ICN ➔ NRT (도쿄)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: PriceAnalyzer.analyzePrice(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          } else if (snapshot.hasError || snapshot.data?['status'] == PriceStatus.error) {
            return Center(child: Text('데이터 통신 오류\n${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final isGreen = data['status'] == PriceStatus.green;
          final currentPrice = data['currentPrice'] as int;
          final averagePrice = data['averagePrice'] as int;
          final priceDifference = (averagePrice - currentPrice).abs();
          final minHour = data['historyData'] != null && (data['historyData'] as List).isNotEmpty
              ? (data['historyData'] as List).map((e) => e.hourOfDay).reduce((a, b) => a < b ? a : b)
              : 0;
          if (!isGreen) _startCountdown(minHour);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isGreen ? "🔥 알고리즘 덤핑 포착!" : "⚠️ 알고리즘 할증 주의",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isGreen ? Colors.greenAccent : Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isGreen ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '일반 평균가',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      ),
                      Text(
                        '₩ ${currencyFormat.format(averagePrice)}',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Icon(Icons.arrow_downward_rounded, color: isGreen ? Colors.greenAccent : Colors.redAccent, size: 28),
                      const SizedBox(height: 16),
                      Text(
                        isGreen ? '현재 타임특가' : '현재 부풀려진 가격',
                        style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₩ ${currencyFormat.format(currentPrice)}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isGreen ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isGreen 
                              ? '지금 결제하면 ${currencyFormat.format(priceDifference)}원 이득!' 
                              : '지금 결제하면 ${currencyFormat.format(priceDifference)}원 손해!',
                          style: TextStyle(
                            color: isGreen ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (!isGreen) ...[
                        const SizedBox(height: 16),
                        _buildCountdownTimer(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 24시간 가격 추이 차트
                if (data['historyData'] != null)
                  Container(
                    height: 220,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildLineChart((data['historyData'] as List<dynamic>).map((e) => {
                      'timestamp': e.timestamp.toIso8601String(),
                      'price_krw': e.priceKrw
                    }).toList()),
                  ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGreen ? Colors.greenAccent.shade400 : Colors.grey.shade800,
                    foregroundColor: isGreen ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: isGreen ? 8 : 0,
                  ),
                  onPressed: isGreen ? _launchAffiliateLink : () {
                    debugPrint("알림 설정 모달 띄우기");
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isGreen ? Icons.shopping_cart_checkout : Icons.notifications_active),
                      const SizedBox(width: 8),
                      Text(
                        isGreen ? '최저가로 즉시 결제하기' : '가격이 떨어지면 알림 받기',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

void main() => runApp(TimeHackerApp());

class TimeHackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time-Hacker',
      home: FlightPatternPage(),
    );
  }
}

class FlightPatternPage extends StatefulWidget {
  @override
  _FlightPatternPageState createState() => _FlightPatternPageState();
}

class _FlightPatternPageState extends State<FlightPatternPage> {
  List<dynamic> rawData = [];
  bool isLoading = true;
  String error = '';

  // 실제 API URL로 교체하세요 (예: GitHub Pages)
  final String apiUrl = 'https://your-username.github.io/your-repo/flight_pricing_history.json';

  // 분석 결과
  double todayAvg = 0;
  int currentPrice = 0;
  double percentDiff = 0;
  String signal = 'RED'; // RED or GREEN
  int minPrice = 0;
  int minHour = 0;
  int currentHour = 0;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          // 오늘 날짜 데이터만 필터
          final now = DateTime.now();
          final today = data.where((e) {
            final t = DateTime.parse(e['timestamp']);
            return t.year == now.year && t.month == now.month && t.day == now.day;
          }).toList();

          // 오늘 평균가
          double avg = 0;
          if (today.isNotEmpty) {
            avg = today.map((e) => e['price_krw'] as int).reduce((a, b) => a + b) / today.length;
          }

          // 최신 데이터
          final latest = today.isNotEmpty ? today.last : data.last;
          int curPrice = latest['price_krw'];
          DateTime curTime = DateTime.parse(latest['timestamp']);
          int curHour = curTime.hour;

          // 퍼센트 차이
          double diff = avg > 0 ? ((curPrice - avg) / avg * 100) : 0;

          // 최저가 시간대
          int minP = curPrice;
          int minH = curHour;
          if (today.isNotEmpty) {
            var minEntry = today.reduce((a, b) => a['price_krw'] < b['price_krw'] ? a : b);
            minP = minEntry['price_krw'];
            minH = DateTime.parse(minEntry['timestamp']).hour;
          }

          // 신호등 상태
          String sig = (diff <= -10) ? 'GREEN' : 'RED';

          setState(() {
            rawData = data;
            todayAvg = avg;
            currentPrice = curPrice;
            percentDiff = diff;
            signal = sig;
            minPrice = minP;
            minHour = minH;
            currentHour = curHour;
            lastUpdate = curTime;
            isLoading = false;
          });
          _startCountdown();
        } else {
          setState(() {
            error = '데이터가 없습니다.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = '데이터를 불러오지 못했습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = '네트워크 오류: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('✈️ Time-Hacker'),
            SizedBox(width: 12),
            Text('[ICN ➔ NRT]', style: TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() { isLoading = true; });
              fetchData();
            },
          ),
          if (lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '업데이트: ${_formatTimeAgo(lastUpdate!)}',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 신호등 Hero Card
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: signal == 'GREEN' ? Colors.green[400] : Colors.red[400],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  import 'package:flutter/material.dart';
                                  import 'package:intl/intl.dart';
                                  import 'package:url_launcher/url_launcher.dart';
                                  import 'price_analyzer.dart';

                                  void main() {
                                    runApp(const TimeHackerApp());
                                  }

                                  class TimeHackerApp extends StatelessWidget {
                                    const TimeHackerApp({super.key});

                                    @override
                                    Widget build(BuildContext context) {
                                      return MaterialApp(
                                        title: 'Time-Hacker',
                                        theme: ThemeData(
                                          brightness: Brightness.dark,
                                          primarySwatch: Colors.blue,
                                        ),
                                        home: const DashboardScreen(),
                                      );
                                    }
                                  }

                                  class DashboardScreen extends StatefulWidget {
                                    const DashboardScreen({super.key});

                                    @override
                                    State<DashboardScreen> createState() => _DashboardScreenState();
                                  }

                                    final currencyFormat = NumberFormat('#,###', 'en_US');

                                    // 🔗 제휴 마케팅 링크 연결 로직 (url_launcher)
                                    Future<void> _launchAffiliateLink() async {
                                      // 본인이 발급받은 파트너스 링크(CPA/CPS)를 여기에 입력합니다.
                                      final Uri url = Uri.parse('https://app.trip.com/광고코드/인천-도쿄');
                                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                        debugPrint('링크를 열 수 없습니다: $url');
                                      }
                                    }

                                    @override
                                    Widget build(BuildContext context) {
                                      return Scaffold(
                                        backgroundColor: const Color(0xFF121212),
                                        appBar: AppBar(
                                          title: const Text('✈️ ICN ➔ NRT (도쿄)'),
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          actions: [
                                            IconButton(
                                              icon: const Icon(Icons.refresh),
                                              onPressed: () => setState(() {}),
                                            ),
                                          ],
                                        ),
                                        body: FutureBuilder<Map<String, dynamic>>(
                                          future: PriceAnalyzer.analyzePrice(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
                                            } else if (snapshot.hasError || snapshot.data?['status'] == PriceStatus.error) {
                                              return Center(child: Text('데이터 통신 오류\n${snapshot.error}', style: const TextStyle(color: Colors.white)));
                                            }

                                            final data = snapshot.data!;
                                            final isGreen = data['status'] == PriceStatus.green;
                                            final currentPrice = data['currentPrice'] as int;
                                            final averagePrice = data['averagePrice'] as int;
                                            final priceDifference = (averagePrice - currentPrice).abs();

                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    isGreen ? "🔥 알고리즘 덤핑 포착!" : "⚠️ 알고리즘 할증 주의",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: isGreen ? Colors.greenAccent : Colors.redAccent,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Container(
                                                    padding: const EdgeInsets.all(24.0),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1E1E1E),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: isGreen ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          '일반 평균가',
                                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                                        ),
                                                        Text(
                                                          '₩ ${currencyFormat.format(averagePrice)}',
                                                          style: TextStyle(
                                                            fontSize: 22,
                                                            color: Colors.grey.shade500,
                                                            decoration: TextDecoration.lineThrough,
                                                            decorationThickness: 2,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Icon(Icons.arrow_downward_rounded, color: isGreen ? Colors.greenAccent : Colors.redAccent, size: 28),
                                                        const SizedBox(height: 16),
                                                        Text(
                                                          isGreen ? '현재 타임특가' : '현재 부풀려진 가격',
                                                          style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                                                        ),
                                                        Text(
                                                          '₩ ${currencyFormat.format(currentPrice)}',
                                                          style: const TextStyle(
                                                            fontSize: 40,
                                                            fontWeight: FontWeight.w900,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                          decoration: BoxDecoration(
                                                            color: isGreen ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            isGreen 
                                                                ? '지금 결제하면 ${currencyFormat.format(priceDifference)}원 이득!' 
                                                                : '지금 결제하면 ${currencyFormat.format(priceDifference)}원 손해!',
                                                            style: TextStyle(
                                                              color: isGreen ? Colors.greenAccent : Colors.redAccent,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: isGreen ? Colors.greenAccent.shade400 : Colors.grey.shade800,
                                                      foregroundColor: isGreen ? Colors.black : Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                      elevation: isGreen ? 8 : 0,
                                                    ),
                                                    onPressed: isGreen ? _launchAffiliateLink : () {
                                                      debugPrint("알림 설정 모달 띄우기");
                                                    }, 
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(isGreen ? Icons.shopping_cart_checkout : Icons.notifications_active),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          isGreen ? '최저가로 즉시 결제하기' : '가격이 떨어지면 알림 받기',
                                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 32),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  }
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.yellow[700],
                                        foregroundColor: Colors.black,
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        // TODO: 제휴 링크로 이동
                                      },
                                      child: Text('트립닷컴 최저가 ${_formatPrice(currentPrice)}원 결제하러 가기 ➔'),
                                    )
                                  : OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: Colors.white, width: 2),
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        // TODO: 알림 권한 요청
                                      },
                                      child: Text('가격 떨어지면 알림 받기 🔔'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      // ... (추후 차트, 데이터 증거 영역 등 추가)
                    ],
                  ),
                ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  int _minutesToNext(int targetHour) {
    final now = DateTime.now();
    int nowMinutes = now.hour * 60 + now.minute;
    int targetMinutes = targetHour * 60;
    int diff = targetMinutes - nowMinutes;
    if (diff < 0) diff += 24 * 60;
    return diff;
  }
}

