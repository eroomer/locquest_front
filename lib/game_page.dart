import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'dart:async';

class GamePage extends StatefulWidget {
  final bool isExplorer;

  const GamePage({super.key, required this.isExplorer});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<Location> _locations = [
    Location(imagePath: 'assets/images/test_image1.jpg', name: '장소 1'),
    Location(imagePath: 'assets/images/test_image2.jpg', name: '장소 2'),
    Location(imagePath: 'assets/images/test_image3.jpg', name: '장소 3'),
    Location(imagePath: 'assets/images/test_image1.jpg', name: '장소 1'),
    Location(imagePath: 'assets/images/test_image2.jpg', name: '장소 2'),
  ];

  @override
  void initState() {
    super.initState();
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
          // 지도 영역 (대체로 Kakao Map 위젯이 들어갈 자리)
          Container(
            color: Colors.grey[300],
            child: const Center(child: Text('카카오맵 영역')),
          ),

          // 아래쪽 슬라이딩 패널
          PhotoDrawerPanel(
            locations: _locations,
            pageController: _pageController,
            currentPage: _currentPage,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
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

  const PhotoDrawerPanel({
    super.key,
    required this.locations,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  State<PhotoDrawerPanel> createState() => _PhotoDrawerPanelState();
}

class _PhotoDrawerPanelState extends State<PhotoDrawerPanel> {
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
        minHeight: 120,
        maxHeight: 450,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        panel: Column(
          children: [
            _buildPanelHandle(),
            Expanded(
              child: Stack(
                children: [
                  PageView(
                    controller: widget.pageController,
                    onPageChanged: widget.onPageChanged,
                    children: widget.locations
                        .map((loc) => LocationCard(location: loc))
                        .toList(),
                  ),
                  if (widget.currentPage > 0)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 32),
                        onPressed: () {
                          widget.pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                  if (widget.currentPage < widget.locations.length - 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 32),
                        onPressed: () {
                          widget.pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                ],
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
  int hintUsed = 0;

  Location({
    required this.imagePath,
    required this.name,
  });
}

class LocationCard extends StatelessWidget {
  final Location location;
  const LocationCard({super.key, required this.location});

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
          const SizedBox(height: 16),

          // 🧭 힌트 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: 힌트 표시 로직
                  print('힌트 버튼 눌림');
                },
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
                onPressed: () {
                  // TODO: 정답 도전 로직
                  print('정답 도전 버튼 눌림');
                },
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
        ],
      ),
    );
  }
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

