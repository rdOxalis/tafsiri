class TranslationEntry {
  final int? id;
  final String sourceText;
  final String resultText;
  final String sourceLang;
  final String targetLang;
  final String aiProvider;
  final bool isFavourite;
  final DateTime createdAt;

  const TranslationEntry({
    this.id,
    required this.sourceText,
    required this.resultText,
    required this.sourceLang,
    required this.targetLang,
    required this.aiProvider,
    this.isFavourite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'source_text': sourceText,
        'result_text': resultText,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'ai_provider': aiProvider,
        'is_favourite': isFavourite ? 1 : 0,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory TranslationEntry.fromMap(Map<String, dynamic> map) =>
      TranslationEntry(
        id: map['id'] as int?,
        sourceText: map['source_text'] as String,
        resultText: map['result_text'] as String,
        sourceLang: map['source_lang'] as String,
        targetLang: map['target_lang'] as String,
        aiProvider: map['ai_provider'] as String,
        isFavourite: (map['is_favourite'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  TranslationEntry copyWith({bool? isFavourite}) => TranslationEntry(
        id: id,
        sourceText: sourceText,
        resultText: resultText,
        sourceLang: sourceLang,
        targetLang: targetLang,
        aiProvider: aiProvider,
        isFavourite: isFavourite ?? this.isFavourite,
        createdAt: createdAt,
      );
}
