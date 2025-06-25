import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/story.dart';
import 'story_reader_page.dart';

class StoryListPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  StoryListPage({
    required this.isDarkMode,
    required this.onToggleTheme,
  });
  @override
  _StoryListPageState createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
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
  List<Story> _stories = [];
  Map<String,int> _progress = {};
  Set<String> _favorites = {};
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStories();
    _loadFavorites();
    _ctrl.addListener(() => setState(() => _query = _ctrl.text.trim()));
  }

  Future<void> _loadStories() async {
    var tmp = <Story>[];
    for (var p in _assetFiles) {
      final data = await DefaultAssetBundle.of(context).loadString(p);
      tmp.add(Story.fromJson(json.decode(data)));
    }
    final prefs = await SharedPreferences.getInstance();
    final prog = <String,int>{};
    for (var s in tmp) {
      prog[s.id] = prefs.getInt('progress_${s.id}') ?? 0;
    }
    setState(() {
      _stories = tmp;
      _progress = prog;
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final fav = prefs.getStringList('favorites') ?? [];
    setState(() => _favorites = fav.toSet());
  }

  Future<void> _toggleFav(String id) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(id)) _favorites.remove(id);
      else _favorites.add(id);
    });
    await prefs.setStringList('favorites', _favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _stories
        .where((s) => s.title.contains(_query))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('故事選單'),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: widget.isDarkMode ? '淺色模式' : '深色模式',
          ),

          // 原本的選單只保留「主畫面」和「我的最愛」
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'home') Navigator.pushReplacementNamed(context, '/');
              if (v == 'fav')  Navigator.pushNamed(context, '/favorites');
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'home', child: Text('主畫面')),
              PopupMenuItem(value: 'fav',  child: Text('我的最愛')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12,12,12,4),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: '搜尋故事標題',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
              child: Text(
                _query.isEmpty ? '尚無故事' : '找不到「$_query」',
                style: TextStyle(fontSize: 16),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: filtered.length,
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.5,
                ),
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  final read = _progress[s.id] ?? 0;
                  final prog = (read + 1) / s.lines.length;
                  final fav = _favorites.contains(s.id);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StoryReaderPage(story: s),
                      ),
                    ).then((_) => _loadStories()),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16)),
                      elevation: 4,
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 7,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top:
                                      Radius.circular(16)),
                                  child: Image.asset(
                                    'assets/covers/${s.id}.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                                child: LinearProgressIndicator(
                                  value: prog,
                                  minHeight: 6,
                                  backgroundColor:
                                  Colors.grey[300],
                                  valueColor:
                                  AlwaysStoppedAnimation(
                                      Colors.teal),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Center(
                                  child: Text(
                                    s.title,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                fav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: fav
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              onPressed: () =>
                                  _toggleFav(s.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
