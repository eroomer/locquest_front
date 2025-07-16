class GameRecord {
  final int gameId;
  final String gameMode;
  final bool success;
  final DateTime gameDate;
  final int? hintCount;
  final int categoryId;

  GameRecord({
    required this.gameId,
    required this.gameMode,
    required this.success,
    required this.gameDate,
    required this.hintCount,
    required this.categoryId,
  });

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      gameId: json['gameId'],
      gameMode: json['gameMode'],
      success: json['success'] ?? false,
      gameDate: DateTime.parse(json['gameDate']),
      hintCount: json['hintCount'],
      categoryId: json['categoryId'],
    );
  }
}
