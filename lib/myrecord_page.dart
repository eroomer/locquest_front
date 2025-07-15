import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/record_service.dart';
import 'package:locquest_front/start_page.dart';

final storage = FlutterSecureStorage();

class MyRecordPage extends StatefulWidget {
  const MyRecordPage({super.key});

  @override
  State<MyRecordPage> createState() => _MyRecordPageState();
}

class _MyRecordPageState extends State<MyRecordPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedRegion = '전체';
  final List<String> regions = ['전체', '카이스트', '어은동', '궁동'];
  late String selectedMode;
  late List<RecordEntry> records = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedMode = 'Explorer';

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        selectedMode = _tabController.index == 0 ? 'Explorer' : 'Time Attack';
      });
    });

    _fetchRecords();
  }

  void _fetchRecords() async {
    try {
      final userId = await loadUserId(); // secure_storage에서 userId 읽기

      if (userId == null) {
        print('userId가 없습니다. 로그인 필요');
        return;
      }

      final gameRecords = await RecordService.fetchGameRecords(userId); // userId는 String

      setState(() {
        records = gameRecords.map((gr) {
          return RecordEntry(
            gameId: gr.gameId,
            mode: gr.gameMode.toLowerCase() == 'explorer' ? 'Explorer' : 'Time Attack',
            region: _mapCategoryIdToRegion(gr.categoryId),
            date: gr.gameDate,
            result: gr.success ? '성공' : '실패',
            places: [], // 아직 위치 정보는 없으므로 빈 리스트
          );
        }).toList();
      });
    } catch (e) {
      print('에러 발생: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = records.where((r) =>
    r.mode == selectedMode &&
        (selectedRegion == '전체' || selectedRegion == r.region)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        actions: [
          _buildRegionFilter(),
        ],
      ),
      body: Column(
        children: [
          MyProfileCard(
              nickname: 'default_user',
              profileImageUrl: 'https://picsum.photos/600/400',
              onLogout: () => _handleLogout(context),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Explorer'),
              Tab(text: 'Time Attack'),
            ],
          ),
          Expanded(
            child: RecordList(records: filteredRecords),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    await storage.delete(key: 'userId'); // userId 삭제

    // 필요 시 다른 값도 삭제 가능
    await storage.deleteAll();

    // 홈 또는 로그인 페이지로 이동
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => StartPage()),
          (route) => false,
    );
  }

  Widget _buildRegionFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text("지역: "),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedRegion,
            items: regions.map((region) {
              return DropdownMenuItem(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedRegion = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class RecordList extends StatelessWidget {
  final List<RecordEntry> records;

  const RecordList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (ctx, idx) {
        final record = records[idx];
        return ListTile(
          title: Text('${record.date.toLocal().toString().split(" ")[0]} - ${record.region}'),
          subtitle: Text('${record.mode} | 결과: ${record.result}'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showDetailDialog(context, record),
        );
      },
    );
  }

  void _showDetailDialog(BuildContext context, RecordEntry record) async {
    try {
      final locations = await RecordService.fetchGameDetail(record.gameId);
      final latLngList = locations.map((e) => e.toLatLng()).toList();

      // record.places에 할당 (만약 immutable이면 별도 처리)
      record.places.clear();
      record.places.addAll(latLngList);

      // 다이얼로그는 fetch가 끝난 후 띄움
      showDialog(
        context: context,
        builder: (ctx) {
          late KakaoMapController mapController;

          return AlertDialog(
            title: const Text('게임 세부 정보'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 300,
                  height: 200,
                  child: KakaoMap(
                    onMapCreated: (controller) {
                      mapController = controller;
                      final markers = <Marker>[];

                      for (int i = 0; i < record.places.length; i++) {
                        markers.add(
                          Marker(
                            markerId: '${record.gameId}_$i',
                            latLng: record.places[i],
                            width: 30,
                            height: 40,
                          ),
                        );
                      }

                      mapController.addMarker(markers: markers.toList());

                      final bounds = _calculateBounds(record.places);
                      final center = LatLng(
                        ((bounds['minLat'] as double) + (bounds['maxLat'] as double)) / 2,
                        ((bounds['minLng'] as double) + (bounds['maxLng'] as double)) / 2,
                      );
                      controller.setCenter(center);

                      final latRange = (bounds['maxLat'] as double) - (bounds['minLat'] as double);
                      final zoomLevel = _getZoomLevel(latRange);
                      mapController.setLevel(zoomLevel);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('모드: ${record.mode}'),
                      Text('지역: ${record.region}'),
                      Text('날짜: ${record.date.toLocal()}'),
                      Text('결과: ${record.result}'),
                    ],
                  ),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              )
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('에러'),
          content: Text('세부 정보를 불러오지 못했습니다.\n$e'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기'))],
        ),
      );
    }
  }

  Map<String, double> _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  int _getZoomLevel(double latRange) {
    if (latRange < 0.001) return 6;
    if (latRange < 0.005) return 5;
    if (latRange < 0.01) return 4;
    if (latRange < 0.02) return 3;
    return 2;
  }
}

class RecordEntry {
  final int gameId;
  final String mode;
  final String region;
  final DateTime date;
  final String result;
  final List<LatLng> places;

  RecordEntry({
    required this.gameId,
    required this.mode,
    required this.region,
    required this.date,
    required this.result,
    required this.places,
  });
}

class MyProfileCard extends StatelessWidget {
  final String nickname;
  final String profileImageUrl;
  final VoidCallback onLogout;

  const MyProfileCard({
    super.key,
    required this.nickname,
    required this.profileImageUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(profileImageUrl),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 20),

            // 닉네임 + 로그아웃 버튼
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _mapCategoryIdToRegion(int id) {
  switch (id) {
    case 1:
      return '카이스트';
    case 2:
      return '어은동';
    case 3:
      return '궁동';
    default:
      return '전체';
  }
}

Future<String?> loadUserId() async {
  final storage = FlutterSecureStorage();
  return await storage.read(key: 'userId');
}



