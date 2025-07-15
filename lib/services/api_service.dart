import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/game_start_response.dart';

final storage = FlutterSecureStorage();

class ApiService {
  Future<GameStartResponse> startGame(int categoryId, String gameMode) async {
    final uri = Uri.parse('http://34.47.75.182/game/startGame');
    final now = DateTime.now();

    // 1. secure storage에서 userId 읽기
    final userId = await storage.read(key: 'userId');
    if (userId == null) {
      throw Exception('userId not found in secure storage.');
    }

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'locCategory': categoryId,
        'gameMode': gameMode,
        'startTime': now.toIso8601String(),
        'gameDate': DateFormat('yyyy-MM-dd').format(now)
      }),
    );

    if (resp.statusCode != 200) {
      print(resp.statusCode);
      throw Exception('Failed to start game: ${resp.statusCode}');
    }
    return GameStartResponse.fromJson(jsonDecode(resp.body));
  }
}
