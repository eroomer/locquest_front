import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:locquest_front/start_page.dart';
import 'package:locquest_front/ranking_page.dart';
import 'package:locquest_front/auth_check_page.dart';
import 'package:locquest_front/add_location_page.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

void main() {
  AuthRepository.initialize(appKey: '536d4da453db14920558d4b8e1e2ed03');
  KakaoSdk.init(nativeAppKey: 'd1847048a1f58aeb83b34e2914f689c8');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LocQuest',
      //home: AddLocationPage(),
      home: AuthCheckPage(),
    );
  }
}