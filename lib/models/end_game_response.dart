class EndGameResponse {
  final double elapsedSeconds;

  EndGameResponse({ required this.elapsedSeconds });

  factory EndGameResponse.fromJson(Map<String, dynamic> json) {
    return EndGameResponse(
      elapsedSeconds: (json['elapsedSeconds'] as num).toDouble(),
    );
  }
}