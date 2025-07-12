import 'dart:async';
import 'package:flutter/material.dart';

class GameTimerController extends ChangeNotifier {
  final bool isExplorer;
  final int explorerTimeSeconds;

  late Timer _timer;
  int _elapsed = 0;
  bool _isRunning = false;

  GameTimerController({
    required this.isExplorer,
    this.explorerTimeSeconds = 3600,
  });

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed++;
      notifyListeners();

      if (isExplorer && _elapsed >= explorerTimeSeconds) {
        stop();
        notifyListeners(); // 알림 전파 (종료 감지용)
      }
    });
  }

  void stop() {
    _isRunning = false;
    _timer.cancel();
  }

  String get formattedTime {
    final seconds = isExplorer
        ? (explorerTimeSeconds - _elapsed).clamp(0, explorerTimeSeconds)
        : _elapsed;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get isOver => isExplorer && _elapsed >= explorerTimeSeconds;
}
