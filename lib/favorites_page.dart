import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/story.dart';
import 'story_reader_page.dart';

class FavoritesPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  FavoritesPage({
    required this.isDarkMode,
    required this.onToggleTheme,
  });
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<Set<String>> _favIdsFuture;
  final List<String> _assetFiles = [
    'assets/stories/story1.json',
    'assets/stories/story2.json',
    'assets/stories/story3.json',
    'assets/stories/story4.json',
    'assets/stories/story5.json',
    'assets/stories/story6.json',
    'assets/stories/story7.json',
    'assets/stories/story8.json',
    'assets/stories/story9.json',
    'assets/stories/story10.json',
  ];

  @override
  void initState() {
    super.initState();
    _favIdsFuture = _loadFavorites();
  }

  Future<Set<String>> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('favorites') ?? []).toSet();
  }

  Future<List<Story>> _loadStories() async {
    var tmp = <Story>[];
    for (var path in _assetFiles) {
      final data =
      await DefaultAssetBundle.of(context).loadString(path);
      tmp.add(Story.fromJson(json.decode(data)));
    }
    return tmp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的最愛'),
        actions: [
          // ← 新增：月亮／太陽圖示按鈕
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: widget.isDarkMode ? '淺色模式' : '深色模式',
          ),

          // 選單只保留「主畫面」和「我的最愛」
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'home')      Navigator.pushReplacementNamed(context, '/');
              if (v == 'favorites') Navigator.pushReplacementNamed(context, '/favorites');
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'home',      child: Text('主畫面')),
              PopupMenuItem(value: 'favorites', child: Text('我的最愛')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Set<String>>(
        future: _favIdsFuture,
        builder: (ctx, snapFav) {
          if (!snapFav.hasData) return Center(child: CircularProgressIndicator());
          return FutureBuilder<List<Story>>(
            future: _loadStories(),
            builder: (ctx2, snapStories) {
              if (!snapStories.hasData) return Center(child: CircularProgressIndicator());
              final favList = snapStories.data!
                  .where((s) => snapFav.data!.contains(s.id))
                  .toList();
              if (favList.isEmpty) {
                return Center(child: Text('尚未加入最愛'));
              }
              return ListView.builder(
                itemCount: favList.length,
                itemBuilder: (_, i) {
                  final s = favList[i];
                  return ListTile(
                    title: Text(s.title),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryReaderPage(story: s),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
