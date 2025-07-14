class GameStartResponse {
  final int gameId;
  final int locCategory;
  final List<LocationModel> locationList;

  GameStartResponse({
    required this.gameId,
    required this.locCategory,
    required this.locationList,
  });

  factory GameStartResponse.fromJson(Map<String, dynamic> json) {
    return GameStartResponse(
      gameId: json['gameId'] as int,
      locCategory: json['locCategory'] as int,
      locationList: (json['locationList'] as List)
          .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LocationModel {
  final int locId;
  final String name;
  final String imagePath;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.locId,
    required this.name,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      locId: (json['locId'] as num).toInt(),
      name: json['locName'] as String,
      imagePath: json['locImage'] as String,
      latitude: (json['locLat'] as num).toDouble(),
      longitude: (json['locLng'] as num).toDouble(),
    );
  }
}