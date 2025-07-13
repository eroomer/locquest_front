import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

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
  late List<RecordEntry> records;

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

    _generateRecords();
  }

  void _generateRecords() {
    records = List.generate(10, (i) {
      final baseLat = 36.372;
      final baseLng = 127.362;
      return RecordEntry(
        id: i,
        mode: i % 2 == 0 ? 'Explorer' : 'Time Attack',
        region: regions[(i % (regions.length - 1)) + 1],
        date: DateTime.now().subtract(Duration(days: i)),
        result: i % 2 == 0 ? '성공' : '실패',
        places: List.generate(
          3 + i % 3,
              (j) => LatLng(baseLat + j * 0.001, baseLng + j * 0.0015),
        ),
      );
    });
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
        title: const Text('참여 기록'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explorer'),
            Tab(text: 'Time Attack'),
          ],
        ),
        actions: [
          _buildRegionFilter(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RecordList(records: filteredRecords),
          ),
        ],
      ),
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

  void _showDetailDialog(BuildContext context, RecordEntry record) {
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
                          markerId: '${record.id}_$i',
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
  final int id;
  final String mode;
  final String region;
  final DateTime date;
  final String result;
  final List<LatLng> places;

  RecordEntry({
    required this.id,
    required this.mode,
    required this.region,
    required this.date,
    required this.result,
    required this.places,
  });
}
