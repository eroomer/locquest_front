import 'package:flutter/material.dart';
import 'package:locquest_front/mode_select_page.dart';
import 'package:locquest_front/ranking_page.dart';
import 'package:locquest_front/myrecord_page.dart';
import 'package:locquest_front/select_category_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo_transparent.png'),
          CustomButton(text: '게임시작', onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SelectCategoryPage()),
            );
          }),
          CustomButton(text: '랭킹보기', onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RankingPage()),
            );
          }),
          CustomButton(text: '내 정보', onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyRecordPage()),
            );
          }),
        ],
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(400, 100),
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

