// lib/tts_client.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class TtsClient {
  Future<Uint8List?> synthesizeTLPABytes({
    required String text,
    required String gender,
    required String accent,
  }) async {
    final uri = Uri.parse('http://tts001.iptcloud.net:8804/synthesize_TLPA').replace(
      queryParameters: {
        'text1': text,
        'gender': gender,
        'accent': accent,
      },
    );
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      //debugPrint('TLPA GET error ${resp.statusCode}: ${resp.body}');
      return null;
    }
    return resp.bodyBytes;
  }
}
