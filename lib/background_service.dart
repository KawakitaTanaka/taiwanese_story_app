// lib/background_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class BackgroundService {
  
  static const _openAiKey = 'sk-proj-fI-ihNJ-sD4i7.....';

  static Future<File> fetchBackground({
    required String storyId,
    required int pageIndex,
    required String prompt,
    bool force = false,
  }) async {
    print('➡️ OpenAI Key prefix: ${_openAiKey.substring(0,6)}…');
    print('➡️ Prompt: $prompt');
    final dir = await getApplicationSupportDirectory();
    final bgDir = Directory('${dir.path}/backgrounds');
    if (!await bgDir.exists()) await bgDir.create(recursive: true);

    final file = File('${bgDir.path}/${storyId}_$pageIndex.png');
    if (await file.exists() && !force) return file;
    if (await file.exists() && force) {
      await file.delete();
    }

    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/images/generations'),
      headers: {
        'Authorization': 'Bearer $_openAiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'dall-e-3',
        'prompt': prompt,
        'size': '1024x1024',
        'n': 1,
      }),
    );
    if (resp.statusCode != 200) {
      print('➡️ DALL·E 错误 ${resp.statusCode}: ${resp.body}');
      throw Exception('背景生成失败');
    }
    final data = jsonDecode(resp.body);
    final url = data['data'][0]['url'];
    final img = await http.get(Uri.parse(url));
    if (img.statusCode != 200) throw Exception('下载背景图失败');
    await file.writeAsBytes(img.bodyBytes, flush: true);
    return file;
  }
}
