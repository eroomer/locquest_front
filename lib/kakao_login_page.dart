import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk_auth/kakao_flutter_sdk_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'package:locquest_front/start_page.dart';

class KakaoLoginPage extends StatefulWidget {
  const KakaoLoginPage({Key? key}) : super(key: key);

  @override
  State<KakaoLoginPage> createState() => _KakaoLoginPageState();
}

class _KakaoLoginPageState extends State<KakaoLoginPage> {
  static const String _redirectUri =
      'kakaod1847048a1f58aeb83b34e2914f689c8://oauth';
  static const String _serverUrl =
      'http://34.47.75.182:8080/auth/kakaoLogin';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('LocQuest 로그인'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png', // 앱 로고 이미지
                height: 120,
              ),
              const SizedBox(height: 32),
              const Text(
                'LocQuest에 오신 걸 환영합니다!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '위치 기반 미션을 수행하며\n즐거운 탐험을 시작해보세요.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Image.asset(
                    'assets/images/kakao_logo.png', // 카카오 로고 아이콘
                    height: 24,
                  ),
                  label: const Text(
                    '카카오 로그인',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE812), // 카카오 색상
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loginWithKakao
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLoginContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loginWithKakao,
          child: const Text('카카오 로그인'),
        ),
      ],
    );
  }

  Future<void> _loginWithKakao() async {
    _setLoading(true);
    try {
      final authCode = await _getAuthCode();
      debugPrint('[✅ 인가 코드] $authCode');

      await _sendTokenToServer(authCode);

      if (!mounted) return;
      _navigateToStartPage();
    } catch (e, st) {
      debugPrint('[❌ 로그인 에러] $e');
      debugPrint('$st');
      _showErrorSnackBar('로그인에 실패했습니다. 다시 시도해주세요.');
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _getAuthCode() async {
    final installed = await isKakaoTalkInstalled();
    String authCode;
    if (installed) {
      authCode = await AuthCodeClient.instance.authorizeWithTalk(
        redirectUri: _redirectUri,
      );
    } else {
      authCode = await AuthCodeClient.instance.authorize(
        redirectUri: _redirectUri,
      );
    }
    return authCode;
  }

  Future<void> _sendTokenToServer(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'authCode': authCode}),
      );
      if (response.statusCode == 200) {
        debugPrint('[✅ 서버 응답] ${response.body}');
        final _secureStorage = FlutterSecureStorage();
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final jwtToken = data['jwt'] as String;
        final userId = data['userId'] as int;
        final nickname = data['nickname'] as String;
        final profileImage = data['profileImage'] as String;

        await _secureStorage.write(key: 'jwt', value: jwtToken);
        debugPrint('[🔐 JWT 저장 완료] $jwtToken');
        await _secureStorage.write(key: 'userId', value: userId.toString());
        await _secureStorage.write(key: 'nickname', value: nickname);
        await _secureStorage.write(key: 'profileImage', value: profileImage);
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[❌ 토큰 전송 에러] $e');
      rethrow;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _navigateToStartPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const StartPage()),
    );
  }
}
