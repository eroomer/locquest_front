import 'package:flutter/material.dart';
import 'package:locquest_front/start_page.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

void main() {
  AuthRepository.initialize(appKey: '536d4da453db14920558d4b8e1e2ed03');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: StartPage(),
    );
  }
}