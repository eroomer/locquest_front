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
      'http://localhost:8080/auth/kakaoLogin';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('카카오 로그인')),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _buildLoginContent(),
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
        await _secureStorage.write(key: 'jwt', value: jwtToken);
        debugPrint('[🔐 JWT 저장 완료] $jwtToken');
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
