

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:locquest_front/kakao_login_page.dart';
import 'package:locquest_front/start_page.dart';

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});
  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1) Secure Storage에서 JWT 읽기
    final jwt = await _storage.read(key: 'jwt');

    if (jwt != null) {
      // 2) 서버에 검증 요청
      final resp = await http.get(
        Uri.parse('http://localhost:8080/auth/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      );
      if (resp.statusCode == 200) {
        // 3a) 유효하면 홈으로
        _navigate(const StartPage());
        return;
      }
    }
    // 3b) 토큰이 없거나 만료/무효면 로그인 페이지로
    _navigate(const KakaoLoginPage());
  }

  void _navigate(Widget page) {
    // pushReplacement를 사용해 뒤로가기 불가 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 토큰 체크 중에는 로딩 스피너만 보여줍니다
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}