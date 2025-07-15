import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:locquest_front/models/category_model.dart';
import '../models/end_game_response.dart';
import '../models/game_start_response.dart';

class ApiService {
  Future<GameStartResponse> startGame(int categoryId, String gameMode) async {
    final uri = Uri.parse('http://localhost:8080/game/startGame');
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

  Future<void> sendChallengeResult({
    required int userId,
    required int locationId,
    required int gameId,
  }) async {
    final url = Uri.parse('http://localhost:8080/game/sendSuccess');
    final body = jsonEncode({
      'userId': userId,
      'locId': locationId,
      'gameId': gameId,
      'completeDate': DateTime.now().toIso8601String(),
    });

    final headers = {'Content-Type': 'application/json'};

    final response = await http.post(url, body: body, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('결과 전송 실패: ${response.statusCode}');
    }
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final url = Uri.parse('http://localhost:8080/game/getCategories');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> list = json['categoryList'];
      return list.map((item) => CategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('카테고리 불러오기 실패: ${response.statusCode}');
    }
  }

  Future<EndGameResponse> endGame({
    required int gameId,
    required bool success,
    required DateTime endTime,
    required int locCount,
    required int hintCount,
    required List<int> failedLocationIds,
  }) async {
    final url = Uri.parse('http://localhost:8080/game/endGame');
    final body = jsonEncode({
      'gameId': gameId,
      'success': success,
      'endTime': endTime.toIso8601String(),
      'locCount': locCount,
      'hintCount': hintCount,
      'failedLocations':
      failedLocationIds.map((id) => {'locId': id}).toList(),
    });
    final response = await http.post(url,
        headers: {'Content-Type': 'application/json'}, body: body);

    if (response.statusCode != 200) {
      throw Exception('게임 종료 전송 실패: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return EndGameResponse.fromJson(data);
  }
}
