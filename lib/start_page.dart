import 'package:flutter/material.dart';
import 'package:locquest_front/mode_select_page.dart';
import 'package:locquest_front/ranking_page.dart';
import 'package:locquest_front/myrecord_page.dart';
import 'package:locquest_front/select_category_page.dart';
import 'package:locquest_front/add_location_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ← 여기 추가
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_transparent.png'),
              CustomButton(
                text: '게임시작',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SelectCategoryPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: '랭킹보기',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RankingPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: '내 정보',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyRecordPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: '장소 추가',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddLocationPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    required this.text,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 50,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF76c893), // apple green
                Color(0xFF4caf50), // forest green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 23, // 너무 크면 줄여도 좋아
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

