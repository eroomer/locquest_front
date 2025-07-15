import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:locquest_front/services/api_service.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

class GamePage extends StatefulWidget {
  final bool isExplorer;
  final int category;

  const GamePage({
    super.key,
    required this.isExplorer,
    required this.category,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final _api = ApiService();

  late final PageController _pageController;
  int _currentPage = 0;
  int? _durationSeconds;

  late KakaoMapController mapController;
  LatLng currentLatLng = LatLng(37.5665, 126.9780); // 현재 user 좌표 (초기값: 서울)
  List<Set<Circle>> hintCircles = List.generate(5, (_) => <Circle>{});
  Set<Marker> markers = {};
  late MarkerIcon userIcon;
  late int userIconWidth;
  late int userIconHeight;

  late StreamSubscription<Position> _positionSubscription;
  bool isMapReady = false;

  List<Location> _locations = [];
  late final List<Location> allLocations;
  int gameId = 0;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
    _initLocation();
    _fetchGameStart();
    _initLiveLocation();
    _pageController = PageController(viewportFraction: 1.0);
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes}분 ${seconds.toString().padLeft(2, '0')}초';
  }

  Future<void> _fetchGameStart() async {
    try {
      final resp = await _api.startGame(widget.category, widget.isExplorer?'ExplorerMode':'TimeAttackMode');
      // 받아온 locationList를 UI용 Location 객체로 변환
      final locs = resp.locationList.map((m) {
        return Location(
          locId: m.locId,
          name: m.name,
          imagePath: m.imagePath,
          position: LatLng(m.latitude, m.longitude),
        );
      }).toList();

      setState(() {
        _locations = locs;
        allLocations = List<Location>.from(_locations);
        isMapReady = true;
        gameId = resp.gameId;
      });

      // 마커나 초기 지도 센터 설정 등 추가 작업 가능
    } catch (e) {
      // 에러 처리
      debugPrint('gameStart error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('게임 시작에 실패했습니다.')));
    }
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // 게임종료 함수
  Future<void> _endGame({
    required bool isSuccess,
    required int durationSeconds
  }) async {
    String usedTime;
    final endTime = DateTime.now();
    final totalPlaces = allLocations.length;
    final failedLocationIds = _locations.map((loc) => loc.locId).toList();
    final successCount = totalPlaces - _locations.length;
    final hintCount = allLocations.fold(0, (sum, loc) => sum + loc.hintUsed);

    try {
      final result = await _api.endGame(
        gameId: gameId,
        success: isSuccess,
        endTime: endTime,
        locCount: successCount,
        hintCount: hintCount,
        failedLocationIds: failedLocationIds,
      );
      // 서버에서 보내준 elapsedSeconds를 초 단위 int로 변환
      final usedSeconds = result.elapsedSeconds.round();
      usedTime = _formatDuration(usedSeconds);
    } catch (e) {
      print('게임 종료 정보 전송 실패: $e');
      usedTime = _formatDuration(durationSeconds);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isSuccess ? '🎉 게임 완료!' : '⏰ 시간 종료'),
        content: Text(
          isSuccess
              ? '모든 장소를 성공적으로 찾았습니다!\n사용 시간: $usedTime'
              : 'Explorer 모드의 제한 시간이 종료되었습니다!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(), // 게임 화면 종료
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }


  // 유저 마커 이미지 불러오기 함수
  Future<void> _loadMarkerIcon() async {
    // 1. 이미지 원본 크기 읽기
    final data = await rootBundle.load('assets/images/logo_marker.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    userIconWidth = (image.width * 0.05).round();
    userIconHeight = (image.height * 0.05).round();

    // 2. 마커 아이콘 로드
    userIcon = await MarkerIcon.fromAsset('assets/images/logo_marker.png');

    print('✅ 유저 마커 로드 완료: $userIconWidth x $userIconHeight');
  }
  // 지도 초기화 함수
  Future<void> _initLocation() async {
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
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      final newLatLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      if (latlngDistance(currentLatLng, newLatLng) > 1.0) {
        // 실제 마커 업데이트
        setState(() {
          print('유저 마커 갱신, 기존 위치 : (${currentLatLng.latitude}, ${currentLatLng.longitude}) , 이동 좌표 : (${newLatLng.latitude}, ${newLatLng.longitude})');
          Marker player = Marker(markerId: 'player', latLng: currentLatLng, icon: userIcon, width: userIconWidth,
            height: userIconHeight,
            offsetX: userIconWidth ~/ 2,
            offsetY: userIconHeight,
          );
          mapController.addMarker(markers: [player]);
          currentLatLng = newLatLng;
        });
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final api = ApiService();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isExplorer ? 'Explorer Mode' : 'Time Attack Mode'),
        backgroundColor: Colors.green,
        actions: [
          GameTimer(
            isExplorer: widget.isExplorer,
            onTimeOver: (elapsedSeconds) async {
              _showGameOverDialog(context);
              _durationSeconds = elapsedSeconds;
              await _endGame(isSuccess: false, durationSeconds: elapsedSeconds);
            },
          ),
          SizedBox(width: 5),
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
                  Marker player = Marker(markerId: 'player', latLng: currentLatLng, icon: userIcon, width: userIconWidth,
                    height: userIconHeight,
                    offsetX: userIconWidth ~/ 2,
                    offsetY: userIconHeight,
                  );
                  mapController.addMarker(markers: [player]);
                  print('최초 유저 마커 생성');
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
            onCheckAnswer: (Location loc) async {
              final _secureStorage = FlutterSecureStorage();
              final dist = latlngDistance(currentLatLng, loc.position);
              final isSuccess = dist <= 10.0;
              String? userIdStr = await _secureStorage.read(key: 'userId');

              if (isSuccess && userIdStr != null) { // 정답일 경우
                try {
                  await api.sendChallengeResult(
                    userId: int.parse(userIdStr),
                    locationId: loc.locId,
                    gameId: gameId,
                  );
                } catch (e) {
                  print('서버 전송 에러: $e');
                }
              }

              // 장소 찾으면 장소 UI 제거
              setState(() {
                final indexToRemove = _locations.indexOf(loc);
                _locations.removeAt(indexToRemove);
                hintCircles.removeAt(indexToRemove);
                mapController.clearCircle(); // 현재 원도 지움

                // 페이지 초기화 또는 보정
                if (_currentPage >= _locations.length) {
                  _currentPage = _locations.length - 1;
                }
                _pageController.jumpToPage(_currentPage);
              });

              if (_locations.isEmpty) {
                final duration = _durationSeconds ??
                    (widget.isExplorer ? 3600 : 0); // fallback 값 (시간 측정이 없을 경우)

                await _endGame(isSuccess: true, durationSeconds: duration);
              }

              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(isSuccess ? '도전 성공!' : '도전 실패'),
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
  final Future<void> Function(int elapsedSeconds)? onTimeOver; // Explorer 모드에서 시간 다 됐을 때 콜백

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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        if (widget.isExplorer) {
          _seconds--;
        } else {
          _seconds++;
        }
      });

      if (widget.isExplorer && _seconds <= 0) {
        _timer?.cancel();
        if (widget.onTimeOver != null) {
          final totalElapsed = 3600; // Explorer 모드는 3600초 기준
          await widget.onTimeOver!(totalElapsed);
        }
      }
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, size: 18), // 시계 아이콘
        const SizedBox(width: 4), // 아이콘과 텍스트 간격
        Text(
          _format(_seconds),
          style: const TextStyle(fontSize: 16),
        ),
      ],
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
        minHeight: 150,
        maxHeight: 400,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
  final int locId;
  final String imagePath;
  final String name;
  final LatLng position;
  int hintUsed = 0;

  Location({
    required this.locId,
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
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(8),
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
              Text(location.name),
              // 🧭 힌트 버튼
              ElevatedButton.icon(
                onPressed: onHintPressed,
                icon: const Icon(Icons.lightbulb),
                label: const Text('힌트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              // 🏁 정답 도전 버튼
              ElevatedButton.icon(
                onPressed: onCheckAnswerPressed,
                icon: const Icon(Icons.check_circle),
                label: const Text('도전'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  backgroundColor: Colors.black,
                  child: InteractiveViewer(
                    child: Image.network(
                      location.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
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

