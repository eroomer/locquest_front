import 'package:flutter/material.dart';
import 'package:locquest_front/game_page.dart';

import 'models/mode_card_model.dart';

class ModeSelectPage extends StatelessWidget {
  final int categoryId;

  const ModeSelectPage({
    super.key,
    required this.categoryId
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('모드 선택'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '게임 모드를 선택하세요',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ModeCardModel(
              title: 'Explorer Mode',
              description: '제한시간 내 최대한 많은 장소를 찾으세요!',
              imagePath: 'assets/images/map.png',
              onTap: () => showModeDialog(context, 'Explorer Mode', categoryId),
            ),
            const SizedBox(height: 16),
            ModeCardModel(
              title: 'Time Attack Mode',
              description: '주어진 장소를 최대한 빨리 찾아보세요!',
              imagePath: 'assets/images/time.png',
              onTap: () => showModeDialog(context, 'Time Attack Mode', categoryId),
            ),
          ],
        ),
      ),
    );
  }
}

class ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(102, 158, 158, 158),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

void showModeDialog(BuildContext context, String title, int category) {
  final isExplorer = title == 'Explorer Mode';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(
        isExplorer
            ? '60분 동안 얼마나 많은 장소를 찾을 수 있는지 도전하세요.\n제한 시간 안에 최대 점수를 기록해 보세요!\n\n - 5개의 장소가 주어집니다.\n - 힌트는 총 5회 사용할 수 있고, 한 장소에 3번까지 사용가능합니다.\n - 정답시도는 장소별로 3회까지 가능합니다.'
            : '정해진 장소를 얼마나 빠르게 모두 찾는지 겨루는 모드입니다.\n짧은 시간 안에 완수하는 것이 핵심입니다!\n\n - 5개의 장소가 주어집니다.\n - 힌트는 총 5회 사용할 수 있고, 한 장소에 3번까지 사용가능합니다.\n - 정답시도는 장소별로 3회까지 가능합니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GamePage(isExplorer: isExplorer, category: category),
              ),
            );
          },
          child: const Text('게임 시작'),
        ),
      ],
    ),
  );
}
