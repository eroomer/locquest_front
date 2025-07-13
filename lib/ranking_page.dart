import 'package:flutter/material.dart';

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
  late Future<List<RankEntry>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = fetchRankingData(widget.mode, widget.category);
  }

  @override
  void didUpdateWidget(RankingList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode || oldWidget.category != widget.category) {
      _rankingFuture = fetchRankingData(widget.mode, widget.category);
      setState(() {}); // 다시 로딩
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RankEntry>>(
      future: _rankingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('데이터가 없습니다.'));
        }

        final items = snapshot.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, idx) {
            final entry = items[idx];
            return entry.rank <= 3
                ? TopRankCard(rank: entry.rank, nickname: entry.name, score: entry.score)
                : DefaultRankItem(rank: entry.rank, nickname: entry.name, score: entry.score);
          },
        );
      },
    );
  }
}

Future<List<RankEntry>> fetchRankingData(String mode, String category) async {
  await Future.delayed(const Duration(seconds: 1)); // 예시용 로딩 시간

  // 실제로는 Dio, http 등으로 서버 API 호출
  return List.generate(20, (i) {
    return RankEntry(i + 1, '$mode 유저 ${i + 1} ($category)', 1000 - i * 13);
  });
}

class RankEntry {
  final int rank;
  final String name;
  final int score;

  RankEntry(this.rank, this.name, this.score);
}

class TopRankCard extends StatelessWidget {
  final int rank;
  final String nickname;
  final int score;
  const TopRankCard({super.key, required this.rank, required this.nickname, required this.score});

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
        title: Text('닉네임 $rank'),
        subtitle: Text('💯 점수'),
        trailing: Icon(Icons.emoji_events), // 트로피 아이콘
      ),
    );
  }
}

class DefaultRankItem extends StatelessWidget {
  final int rank;
  final String nickname;
  final int score;
  const DefaultRankItem({super.key, required this.rank, required this.nickname, required this.score});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text('$rank'),
      title: Text('닉네임 $rank'),
      trailing: Text('💯 점수'),
    );
  }
}



