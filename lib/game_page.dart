import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

class GamePage extends StatefulWidget {
  final bool isExplorer;

  const GamePage({super.key, required this.isExplorer});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final PageController _pageController;
  late KakaoMapController mapController;
  bool isDefaultMap = true; // 지도 타입(지도/스카이뷰)
  int mapLevel = 5;     // 지도 확대 수준

  Set<Marker> markers = {};
  List<Set<Circle>> hintCircles = List.generate(5, (_) => <Circle>{});
  LatLng currentLatLng = LatLng(37.5665, 126.9780); // 현재 user 좌표 (초기값: 서울)
  bool isMapReady = false;
  int _currentPage = 0;

  final List<Location> _locations = [
    Location(imagePath: 'assets/images/test_image1.jpg', name: '의문의 문', position: LatLng(36.366456, 127.360971)),
    Location(imagePath: 'assets/images/test_image2.jpg', name: '오리벽화', position: LatLng(36.367199, 127.359958)),
    Location(imagePath: 'assets/images/test_image3.jpg', name: '맹꽁이 사다리', position: LatLng(36.366952, 127.359182)),
    Location(imagePath: 'assets/images/test_image4.jpg', name: '산불조심', position: LatLng(36.367044, 127.358994)),
    Location(imagePath: 'assets/images/test_image5.jpg', name: '컨테이너', position: LatLng(36.368302, 127.357846)),
  ];

  @override
  void initState() {
    super.initState();
    initLocation();
    _initLiveLocation();

    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final loc in _locations) {
        precacheImage(AssetImage(loc.imagePath), context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 지도 초기화 함수
  Future<void> initLocation() async {
    print('[initLocation] 위치 요청 시작');
    final loc = await getCurrentLocation();
    if (loc != null) {
      print('[initLocation] 위치 가져오기 성공: \${loc.latitude}, \${loc.longitude}');
      setState(() {
        currentLatLng = loc;
        isMapReady = true; // 지도 렌더링 조건
      });
      //mapController.setCenter(loc);
    }
  }
  // 사용자 위치 추적 시작 함수
  void _initLiveLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final newLatLng = LatLng(position.latitude, position.longitude);

      // 지도 중심 이동
      animateMapCenter(currentLatLng, newLatLng);

      // 현재 위치 갱신
      setState(() {
        currentLatLng = newLatLng;
      });
    });
  }
  // 지도 중심 이동 함수
  void animateMapCenter(LatLng from, LatLng to) async {
    const steps = 30;
    const duration = Duration(milliseconds: 600);

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;

      mapController.setCenter(LatLng(lat, lng));
      await Future.delayed(duration ~/ steps);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isExplorer ? 'Explorer 모드' : 'Time Attack 모드'),
        backgroundColor: Colors.green,
        actions: [
          GameTimer(
            isExplorer: widget.isExplorer,
            onTimeOver: () => _showGameOverDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showGameExitDialog(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isMapReady)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: KakaoMap(
                onMapCreated: ((controller)  {
                  mapController = controller;
                  }),
                center: currentLatLng,
                currentLevel: 5,
                ),
            )
          else
            const Center(child: CircularProgressIndicator()), // 로딩 중

          // 아래쪽 슬라이딩 패널
          PhotoDrawerPanel(
            locations: _locations,
            pageController: _pageController,
            currentPage: _currentPage,
            onPageChanged: (index) {
              setState(() {
                var circles2remove = hintCircles[_currentPage].map((circle) => circle.circleId).toList();
                var circles2add = hintCircles[index].toList();
                mapController.clearCircle(circleIds: circles2remove);
                mapController.addCircle(circles: circles2add);
                _currentPage = index;
              });
            },
            // 힌트 버튼 로직
            onHintPressed: (Location loc) {
              if (loc.hintUsed >= 3) {
                showToastMessage('$_currentPage번 장소에 이미 3개의 힌트를 사용했습니다.');
                return;
              }
              loc.hintUsed++; // 힌트 사용 횟수 증가
              final radius = [200, 100, 50][loc.hintUsed - 1]; // 반경 결정
              final offsetCenter = randomOffsetAround(loc.position, radius.toDouble());

              final circle = Circle(
                circleId: 'hintcircle_${hintCircles[_currentPage].length}',
                center: offsetCenter,
                radius: radius.toDouble(),
                strokeColor: Colors.orange,
                strokeOpacity: 0.5,
                strokeStyle: StrokeStyle.dash,
                strokeWidth: 2,
                fillColor: Colors.orange,
                fillOpacity: 0.2,
              );
              setState(() {
                hintCircles[_currentPage].add(circle); // 원 추가
                mapController.addCircle(circles: hintCircles[_currentPage].toList());
              });
            },
            // 정답 도전 버튼 로직
            onCheckAnswer: (Location loc) {
              final dist = latlngDistance(currentLatLng, loc.position);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('도전 결과'),
                  content: Text('사진 속 장소와 거리: ${dist.toStringAsFixed(1)} m'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GameTimer extends StatefulWidget {
  final bool isExplorer;
  final VoidCallback? onTimeOver; // Explorer 모드에서 시간 다 됐을 때 콜백

  const GameTimer({
    super.key,
    required this.isExplorer,
    this.onTimeOver,
  });

  @override
  State<GameTimer> createState() => _GameTimerState();
}
class _GameTimerState extends State<GameTimer> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();

    if (widget.isExplorer) {
      _seconds = 3600; // 60분 카운트다운
    } else {
      _seconds = 0; // 스톱워치 시작
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (widget.isExplorer) {
          _seconds--;
          if (_seconds <= 0) {
            _timer?.cancel();
            if (widget.onTimeOver != null) widget.onTimeOver!();
          }
        } else {
          _seconds++;
        }
      });
    });
  }

  String _format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.isExplorer
          ? '남은 시간: ${_format(_seconds)}'
          : '경과 시간: ${_format(_seconds)}',
      style: const TextStyle(fontSize: 16),
    );
  }
}

class PhotoDrawerPanel extends StatefulWidget {
  final List<Location> locations;
  final PageController pageController;
  final int currentPage;
  final void Function(int) onPageChanged;
  final void Function(Location location) onHintPressed;
  final void Function(Location location) onCheckAnswer;

  const PhotoDrawerPanel({
    super.key,
    required this.locations,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onHintPressed,
    required this.onCheckAnswer,
  });

  @override
  State<PhotoDrawerPanel> createState() => _PhotoDrawerPanelState();
}

class _PhotoDrawerPanelState extends State<PhotoDrawerPanel> {
  final PanelController _panelController = PanelController();

  Widget _buildPanelHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 6,
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SlidingUpPanel(
        minHeight: MediaQuery.of(context).size.height * 0.1,
        snapPoint: 0.3,
        maxHeight: 450,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        controller: _panelController,
        panel: Column(
          children: [
            _buildPanelHandle(),
            Expanded(
              child: PageView(
                controller: widget.pageController,
                onPageChanged: widget.onPageChanged,
                children: widget.locations.map((loc) => LocationCard(
                  location: loc,
                  onCheckAnswerPressed: () => widget.onCheckAnswer(loc),
                  onHintPressed: () {
                    widget.onHintPressed(loc);
                    _panelController.close();
                  },
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Location {
  final String imagePath;
  final String name;
  final LatLng position;
  int hintUsed = 0;

  Location({
    required this.imagePath,
    required this.name,
    required this.position
  });
}

class LocationCard extends StatelessWidget {
  final Location location;
  final VoidCallback onHintPressed;
  final VoidCallback onCheckAnswerPressed;
  const LocationCard({
    super.key,
    required this.location,
    required this.onHintPressed,
    required this.onCheckAnswerPressed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 🧭 힌트 버튼
              ElevatedButton.icon(
                onPressed: onHintPressed,
                icon: const Icon(Icons.lightbulb),
                label: const Text('힌트 보기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
              ),
              // 🏁 정답 도전 버튼
              ElevatedButton.icon(
                onPressed: onCheckAnswerPressed,
                icon: const Icon(Icons.check_circle),
                label: const Text('정답 도전'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  backgroundColor: Colors.black,
                  child: InteractiveViewer(
                    child: Image.asset(
                      location.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                location.imagePath,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 600,
                cacheHeight: 800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 현재 위치 반환 함수
Future<LatLng?> getCurrentLocation() async {
  print("[getCurrentLocation] 위치 권한 상태 확인 중...");

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    print("[getCurrentLocation] 권한이 거부됨 → 요청 시도");
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    print("[getCurrentLocation] 권한 영구 거부됨 → 설정에서 수동 허용 필요");
    return null;
  }

  if (permission != LocationPermission.whileInUse &&
      permission != LocationPermission.always) {
    print("[getCurrentLocation] 권한 없음 (기타 상태): $permission");
    return null;
  }

  try {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("[getCurrentLocation] 위치 획득: ${pos.latitude}, ${pos.longitude}");
    return LatLng(pos.latitude, pos.longitude);
  } catch (e) {
    print("[getCurrentLocation] 위치 요청 실패: $e");
    return null;
  }
}

double latlngDistance(LatLng pointA, LatLng pointB) {
  return Geolocator.distanceBetween(
    pointA.latitude,
    pointA.longitude,
    pointB.latitude,
    pointB.longitude,
  );
}

LatLng randomOffsetAround(LatLng center, double radiusInMeters) {
  final random = Random();

  // 오프셋 거리: 반지름의 0% ~ 70% 내에서 랜덤
  final distance = (radiusInMeters * (random.nextDouble() * 0.7)); // [0% ~ 70%]
  final bearing = random.nextDouble() * 2 * pi; // [0 ~ 2π]

  const earthRadius = 6371000.0; // meters

  final lat1 = center.latitude * pi / 180;
  final lon1 = center.longitude * pi / 180;

  final lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
      cos(lat1) * sin(distance / earthRadius) * cos(bearing));
  final lon2 = lon1 +
      atan2(sin(bearing) * sin(distance / earthRadius) * cos(lat1),
          cos(distance / earthRadius) - sin(lat1) * sin(lat2));

  return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
}

// 토스트 메시지 출력 함수
void showToastMessage(String message) {
  print("Toast 실행: $message");
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM, // TOP, CENTER, BOTTOM 중 선택 가능
    backgroundColor: Colors.black87,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void _showGameExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('게임 종료'),
      content: const Text('게임을 종료하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // 다이얼로그 닫기
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // 다이얼로그 닫기
            Navigator.of(context).pop(); // 게임 화면 종료
          },
          child: const Text('종료'),
        ),
      ],
    ),
  );
}
void _showGameOverDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // 바깥 탭으로 닫히지 않도록
    builder: (_) => AlertDialog(
      title: const Text('시간 종료'),
      content: const Text('Explorer 모드의 제한 시간이 종료되었습니다!'),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // 다이얼로그 닫기
            Navigator.of(context).pop(); // 게임 화면 종료
          },
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

