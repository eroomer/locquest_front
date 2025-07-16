import 'package:flutter/material.dart';

class ModeCardModel extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;
  final String imagePath;

  const ModeCardModel({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white, // 카드 배경색 (필요 시 수정)
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.grey.withOpacity(0.2),       // 터치 시 퍼지는 물결색
          highlightColor: Colors.grey.withOpacity(0.1),    // 누르고 있을 때 배경색
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  imagePath,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
