// lib/story_reader_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'tts_client.dart';
import 'background_service.dart';
import 'models/story.dart';

class StoryReaderPage extends StatefulWidget {
  final Story story;
  const StoryReaderPage({Key? key, required this.story}) : super(key: key);

  @override
  _StoryReaderPageState createState() => _StoryReaderPageState();
}

class _StoryReaderPageState extends State<StoryReaderPage> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _chosenAccent = '強勢腔（高雄腔）';
  String _chosenGender = '女聲';
  String _bgStyle = '水彩柔和';
  final List<String> _styles = ['水彩柔和','扁平插畫','鉛筆素描'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('progress_${widget.story.id}') ?? 0;
    // 先更新 _currentPage，不要马上 jump
    setState(() {
      _currentPage = saved.clamp(0, widget.story.lines.length - 1);
    });
    // 等到下一帧，PageView 确定 attach 后再跳页
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(_currentPage);
    });
  }

  Future<void> _saveProgress(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_${widget.story.id}', page);
  }

  Future<void> _playTTS() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);

    final text = widget.story.lines[_currentPage];
    try {
      final bytes = await TtsClient().synthesizeTLPABytes(
        text: text,
        gender: _chosenGender,
        accent: _chosenAccent,
      );
      if (bytes != null) {
        await _audioPlayer.setPlaybackRate(_playbackRate);
        // 直接從記憶體播放：
        await _audioPlayer.play(BytesSource(bytes));
      }
    } catch (e) {
      debugPrint('播放失敗: $e');
    }

    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// hasBg=true 時文字用淺色，false 時用深色
  Widget _buildPageContent(String han, String rom, int idx, bool hasBg) {
    final theme = Theme.of(context);
    final defaultText = hasBg
            ? Colors.white
            : theme.colorScheme.onBackground;
    final defaultRoman = hasBg
            ? Colors.white70
            : theme.textTheme.bodyMedium!.color!;
    final isCur = _isPlaying && idx == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            han,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              height: 1.4,
              color: isCur ? Colors.teal : defaultText,
              fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rom,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: isCur ? Colors.teal.shade200 : defaultRoman,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.story.lines;
    final roman = widget.story.romanization;
    final onText = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(title: Text(widget.story.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('腔調：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _chosenAccent,
                  items: const [
                    DropdownMenuItem(value: '強勢腔（高雄腔）', child: Text('強勢腔（高雄腔）')),
                    DropdownMenuItem(value: '次強勢腔（台北腔）', child: Text('次強勢腔（台北腔）')),
                  ],
                  onChanged: (v) => setState(() => _chosenAccent = v!),
                ),
              ],
            ),
          ),

          // 新增：聲別選擇
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text('聲別：', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('男聲'),
                  selected: _chosenGender == '男聲',
                  onSelected: (_) => setState(() => _chosenGender = '男聲'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('女聲'),
                  selected: _chosenGender == '女聲',
                  onSelected: (_) => setState(() => _chosenGender = '女聲'),
                ),
              ],
            ),
          ),
          // 語速 Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('語速', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Slider(
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${_playbackRate.toStringAsFixed(1)}x',
                    value: _playbackRate,
                    onChanged: (v) => setState(() => _playbackRate = v),
                  ),
                ),
                Text('${_playbackRate.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: '背景風格',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              value: _bgStyle,
              items: _styles.map((s) => DropdownMenuItem(child: Text(s), value: s)).toList(),
              onChanged: (v) => setState(() => _bgStyle = v!),
            ),
          ),

          // 內容分頁 + 背景
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: lines.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                  _saveProgress(idx);
                });
              },
              itemBuilder: (_, idx) {
                final prompt = '背景風格：$_bgStyle；第 ${idx + 1} 頁 "${widget.story.title}" 的插圖：${lines[idx]}。';
                return FutureBuilder<File>(
                  future: BackgroundService.fetchBackground(
                    storyId: widget.story.id,
                    pageIndex: idx,
                    prompt: prompt,
                  ),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('生成背景中，請稍候…'),
                          ],
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return _buildPageContent(lines[idx], roman[idx], idx, false);
                    }
                    final file = snap.data!;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 背景圖
                        Image.file(file, fit: BoxFit.cover),
                        // 半透明遮罩
                        Container(color: Colors.black.withOpacity(0.3)),
                        // 故事文字
                        _buildPageContent(lines[idx], roman[idx], idx, true),

                        // ↓ 這就是「重載背景」按鈕，放在右上角
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            tooltip: '重新生成背景',
                            onPressed: () {
                              // 注意：BackgroundService.fetchBackground 需要加上 force 參數
                              BackgroundService.fetchBackground(
                                storyId: widget.story.id,
                                pageIndex: idx,
                                prompt: prompt,
                                force: true, // 強制覆寫已快取檔案
                              ).then((_) {
                                setState(() { /* 觸發重繪頁面，新的背景就會載入 */ });
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: List.generate(lines.length, (i) {
                final isCurrent = i == _currentPage;
                return GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(i);
                    setState(() => _currentPage = i);
                    _saveProgress(i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.teal : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 播放 + 頁碼
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle_fill),
                  iconSize: 36,
                  color: Colors.teal,
                  onPressed: _playTTS,
                ),
                const Spacer(),
                Text(
                  '${_currentPage + 1} / ${lines.length}',
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
