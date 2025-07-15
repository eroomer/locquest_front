import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/record_games_response.dart';
import '../models/record_details_response.dart';

class RecordService {
  static Future<List<GameRecord>> fetchGameRecords(String userId) async {
    final url = Uri.parse('http://34.47.75.182/record/getGames?userId=$userId');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(res.body);
      print('받은 응답');
      print(json.decode(res.body));
      return jsonList.map((e) => GameRecord.fromJson(e)).toList();
    } else {
      throw Exception('게임 기록을 불러오지 못했습니다');
    }
  }

  static Future<List<GameLocation>> fetchGameDetail(int gameId) async {
    final url = Uri.parse('http://localhost:8080/record/gameDetail?gameId=$gameId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      print('받은 응답');
      print(json.decode(response.body));
      return jsonList.map((e) => GameLocation.fromJson(e)).toList();
    } else {
      throw Exception('게임 세부 장소 불러오기 실패');
    }
  }
}
