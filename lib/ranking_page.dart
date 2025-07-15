import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String selectedCategory = '전체';
  final List<String> categories = ['전체', '카이스트', '어은동', '궁동'];

  late String selectedMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedMode = 'Explorer'; // 초기 모드 설정 'Explorer'

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        selectedMode = _tabController.index == 0 ? 'Explorer' : 'Time Attack';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('랭킹'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explorer'),
            Tab(text: 'Time Attack'),
          ],
        ),
        actions: [
          _buildCategoryFilter(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RankingList(mode: selectedMode, category: selectedCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text("지역: "),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: selectedCategory,
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedCategory = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class RankingList extends StatefulWidget {
  final String mode;
  final String category;

  const RankingList({super.key, required this.mode, required this.category});

  @override
  State<RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<RankingList> {
  late Future<List<dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _fetchData();
  }

  @override
  void didUpdateWidget(RankingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode || oldWidget.category != widget.category) {
      _rankingFuture = _fetchData();
      setState(() {});
    }
  }

  Future<List<dynamic>> _fetchData() async {
    final categoryId = _getCategoryId(widget.category); // 예시 변환 함수
    if (widget.mode == 'Explorer') {
      return await fetchExplorerRankingData(categoryId);
    } else {
      return await fetchTimeAttackRankingData(categoryId);
    }
  }

  int _getCategoryId(String categoryName) {
    switch (categoryName) {
      case '카이스트': return 1;
      case '어은동': return 2;
      case '궁동': return 3;
      default: return 0; // 전체
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          debugPrint('FutureBuilder 에러: ${snapshot.error}');
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint('데이터 없음: ${snapshot.data}');
          return const Center(child: Text('데이터가 없습니다.'));
        }

        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final rank = idx + 1;
            final entry = items[idx];

            if (widget.mode == 'Explorer') {
              final e = entry as ExplorerRankEntry;
              return rank <= 3
                  ? TopExplorerRankCard(rank: rank, nickname: e.userName, score: e.locCount, hintUsed: e.hintCount)
                  : DefaultExplorerRankItem(rank: rank, nickname: e.userName, score: e.locCount, hintUsed: e.hintCount);
            } else {
              final t = entry as TimeAttackRankEntry;
              return rank <= 3
                  ? TopTimeAttackRankCard(rank: rank, nickname: t.userName, formattedTime: t.formattedTime)
                  : DefaultTimeAttackRankItem(rank: rank, nickname: t.userName, formattedTime: t.formattedTime);
            }
          },
        );
      },
    );
  }
}

Future<List<ExplorerRankEntry>> fetchExplorerRankingData(int categoryId) async {
  final serverUrl = 'http://localhost:8080/ranking/explorer?categoryId=$categoryId';
  debugPrint('[Explorer] 요청 URL: $serverUrl');

  try {
    final response = await http.get(Uri.parse(serverUrl));
    debugPrint('[Explorer] 응답 상태: ${response.statusCode}');
    debugPrint('[Explorer] 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ExplorerRankEntry.fromJson(json)).toList();
    } else {
      throw Exception('Explorer 랭킹 불러오기 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('[Explorer] 에러 발생: $e');
    rethrow;
  }
}

Future<List<TimeAttackRankEntry>> fetchTimeAttackRankingData(int categoryId) async {
  final serverUrl = 'http://34.47.75.182/ranking/timeAttack?categoryId=$categoryId';
  debugPrint('[TimeAttack] 요청 URL: $serverUrl');

  try {
    final response = await http.get(Uri.parse(serverUrl));
    debugPrint('[TimeAttack] 응답 상태: ${response.statusCode}');
    debugPrint('[TimeAttack] 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => TimeAttackRankEntry.fromJson(json)).toList();
    } else {
      throw Exception('Time Attack 랭킹 불러오기 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('[TimeAttack] 에러 발생: $e');
    rethrow;
  }
}

class ExplorerRankEntry {
  final String userId;
  final String userName;
  final int locCount;
  final int hintCount;

  ExplorerRankEntry({
    required this.userId,
    required this.userName,
    required this.locCount,
    required this.hintCount,
  });

  factory ExplorerRankEntry.fromJson(Map<String, dynamic> json) {
    return ExplorerRankEntry(
      userId: json['userId'],
      userName: json['userName'],
      locCount: json['locCount'],
      hintCount: json['hintCount'],
    );
  }
}

class TimeAttackRankEntry {
  final String userId;
  final String userName;
  final int totalTime; // 초 단위

  TimeAttackRankEntry({
    required this.userId,
    required this.userName,
    required this.totalTime,
  });

  factory TimeAttackRankEntry.fromJson(Map<String, dynamic> json) {
    return TimeAttackRankEntry(
      userId: json['userId'],
      userName: json['userName'],
      totalTime: json['totalTime'],
    );
  }

  // 💡 초 → mm:ss 포맷
  String get formattedTime {
    final minutes = totalTime ~/ 60;
    final seconds = totalTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class TopExplorerRankCard extends StatelessWidget {
  final int rank;
  final String nickname;
  final int score;
  final int hintUsed;
  const TopExplorerRankCard({super.key, required this.rank, required this.nickname, required this.score, required this.hintUsed});

  @override
  Widget build(BuildContext context) {
    final styles = [
      Colors.amber[300],
      Colors.grey[300],
      Color(0xFFCD7F32), // 원하는 색 설정
    ];
    return Card(
      color: styles[rank-1],
      child: ListTile(
        leading: CircleAvatar(child: Text('$rank')),
        title: Text('$nickname'),
        subtitle: Text('찾은 장소 : $score'),
        trailing: Text('사용 힌트 : $hintUsed'),
      ),
    );
  }
}

class DefaultExplorerRankItem extends StatelessWidget {
  final int rank;
  final String nickname;
  final int score;
  final int hintUsed;
  const DefaultExplorerRankItem({super.key, required this.rank, required this.nickname, required this.score, required this.hintUsed});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('$rank'),
      title: Text('$nickname'),
      subtitle: Text('찾은 장소 : $score'),
      trailing: Text('사용 힌트 : $hintUsed'),
    );
  }
}

class TopTimeAttackRankCard extends StatelessWidget {
  final int rank;
  final String nickname;
  final String formattedTime;
  const TopTimeAttackRankCard({super.key, required this.rank, required this.nickname, required this.formattedTime});

  @override
  Widget build(BuildContext context) {
    final styles = [
      Colors.amber[300],
      Colors.grey[300],
      Color(0xFFCD7F32), // 원하는 색 설정
    ];
    return Card(
      color: styles[rank-1],
      child: ListTile(
        leading: CircleAvatar(child: Text('$rank')),
        title: Text('$nickname'),
        subtitle: Text('소요 시간 : $formattedTime'),
      ),
    );
  }
}

class DefaultTimeAttackRankItem extends StatelessWidget {
  final int rank;
  final String nickname;
  final String formattedTime;
  const DefaultTimeAttackRankItem({super.key, required this.rank, required this.nickname, required this.formattedTime});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('$rank'),
      title: Text('$nickname'),
      subtitle: Text('소요 시간 : $formattedTime'),
    );
  }
}



