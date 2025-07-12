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
  final List<String> photoList = [
    'assets/images/test_image1.jpg',
    'assets/images/test_image2.jpg',
    'assets/images/test_image3.jpg',
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
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
            onTimeOver: () {
              // 시간 종료 시 처리
              _showGameOverDialog(context); // 예시 함수
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag), // 예: 종료 버튼
            onPressed: () {
              _showGameExitDialog(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 카카오맵 자리
          Container(
            color: Colors.grey[300], // 실제 지도 대신 임시색
            child: const Center(child: Text('카카오맵 영역')),
          ),
          // 2. 아래 Drawer 패널
          PhotoDrawerPanel(
            photoList: photoList,
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
  final List<String> photoList;
  final PageController pageController;
  final int currentPage;
  final void Function(int) onPageChanged;

  const PhotoDrawerPanel({
    super.key,
    required this.photoList,
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
        minHeight: 100,
        maxHeight: 800,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        panel: Column(
          children: [
            _buildPanelHandle(),
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: widget.pageController,
                    itemCount: widget.photoList.length,
                    onPageChanged: widget.onPageChanged,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        widget.photoList[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),

                  // 왼쪽 화살표
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

                  // 오른쪽 화살표
                  if (widget.currentPage < widget.photoList.length - 1)
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

