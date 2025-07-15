import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/game_start_response.dart';

class ApiService {
  Future<GameStartResponse> startGame(int categoryId, String gameMode) async {
    final uri = Uri.parse('http://34.47.75.182/game/startGame');
    final now = DateTime.now();

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': '4347469885',
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
