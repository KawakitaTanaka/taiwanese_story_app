// lib/models/story.dart

class Story {
  final String id;
  final String title;
  final List<String> lines;
  final List<String> romanization;

  Story({
    required this.id,
    required this.title,
    required this.lines,
    required this.romanization,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    List<String> rawLines = List<String>.from(json['lines']);
    List<String> rawRoman = List<String>.from(json['roman']);
    return Story(
      id: json['id'],
      title: json['title'],
      lines: rawLines,
      romanization: rawRoman,
    );
  }
}

