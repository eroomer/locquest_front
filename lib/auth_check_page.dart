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
  bool _navigated = false; // 네비게이션 중복 방지

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final jwt = await _storage.read(key: 'jwt');
    var valid = false;

    if (jwt != null) {
      try {
        final resp = await http.get(
          Uri.parse('http://localhost:8080/auth/validate'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
        );
        if (resp.statusCode == 200) {
          valid = true;
        } else {
          // 401/403 등 유효하지 않음
          await _storage.delete(key: 'jwt');
        }
      } catch (e) {
        // 네트워크 에러 등
        debugPrint('Auth validation error: $e');
        await _storage.delete(key: 'jwt');
      }
    }

    // 네비게이션은 한 번만
    if (!_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => valid ? const StartPage() : const KakaoLoginPage(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
