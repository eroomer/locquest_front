import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class GameLocation {
  final int locId;
  final String locName;
  final double locLat;
  final double locLng;
  final String locImage;
  final int locFailed;
  final int locSuccessed;

  GameLocation({
    required this.locId,
    required this.locName,
    required this.locLat,
    required this.locLng,
    required this.locImage,
    required this.locFailed,
    required this.locSuccessed,
  });

  factory GameLocation.fromJson(Map<String, dynamic> json) {
    return GameLocation(
      locId: json['locId'],
      locName: json['locName'],
      locLat: json['locLat'],
      locLng: json['locLng'],
      locImage: json['locImage'],
      locFailed: json['locFailed'],
      locSuccessed: json['locSuccessed'],
    );
  }

  LatLng toLatLng() => LatLng(locLat, locLng);
}