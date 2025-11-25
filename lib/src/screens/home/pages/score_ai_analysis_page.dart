import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';

class ScoreAiAnalysisPage extends StatefulWidget {
  const ScoreAiAnalysisPage({super.key});

  @override
  State<ScoreAiAnalysisPage> createState() => _ScoreAiAnalysisPageState();
}

class _ScoreAiAnalysisPageState extends State<ScoreAiAnalysisPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isLoading = false;
  bool _hydrated = false;
  String? _analysis;
  String? _error;
  List<_ScoreSnapshot> _snapshots = [];
  DateTime? _analysisUpdatedAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    _hydrate();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final scope = AuthScope.of(context);
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_apiKeyStorageKey(scope.session.user.userId));
    final rawScores = prefs.getString('scores_${scope.session.user.userId}');
    final saved = prefs.getString(_analysisStorageKey(scope.session.user.userId));
    if (!mounted) return;
    setState(() {
      if (key != null) _apiKeyController.text = key;
      _snapshots = _ScoreSnapshot.parse(rawScores);
      if (saved != null && saved.isNotEmpty) {
        try {
          final data = jsonDecode(saved) as Map<String, dynamic>;
          final content = data['content']?.toString();
          final ts = data['updatedAt']?.toString();
          if (content != null && content.isNotEmpty) {
            _analysis = content;
            _analysisUpdatedAt = ts != null ? DateTime.tryParse(ts) : null;
          }
        } catch (_) {}
      }
    });
  }

  Future<void> _saveKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入有效的 DeepSeek API Key')),
      );
      return;
    }
    final scope = AuthScope.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyStorageKey(scope.session.user.userId), apiKey);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('密钥已保存')),
    );
  }

  Future<void> _runAnalysis() async {
    FocusScope.of(context).unfocus();
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _analysis = null;
        _error = '请先填写并保存 DeepSeek API Key';
      });
      return;
    }
    if (_snapshots.isEmpty) {
      setState(() {
        _analysis = null;
        _error = '未找到本地成绩，请先在“高考信息”页保存成绩记录';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _analysis = null;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content': '你是一名高考志愿与学业规划顾问，请使用简洁的中文回复，结构化给出结论。'
            },
            {
              'role': 'user',
              'content': _buildPrompt(),
            },
          ],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content']?.toString();
        final now = DateTime.now();
        setState(() {
          _analysis = content?.trim().isNotEmpty == true ? content!.trim() : '未获取到有效回复';
          _analysisUpdatedAt = _analysis != null ? now : null;
        });
        if (_analysis != null) {
          await _persistAnalysis(_analysis!, now);
        }
      } else {
        setState(() {
          _analysis = null;
          _error = '调用失败（${response.statusCode}）';
        });
      }
    } catch (err) {
      setState(() {
        _analysis = null;
        _error = '调用异常：$err';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('以下是学生最近的考试成绩，请输出总体趋势、优势科目、薄弱科目，并给出三条学习建议与一条志愿提醒：');
    for (final s in _snapshots) {
      buffer.writeln(
        '- ${s.formattedDate} ${s.label}：总分${s.total.toStringAsFixed(0)}分'
        '${s.rank != null ? '，省排名${s.rank}' : ''}'
        '${s.mode != null && s.mode!.isNotEmpty ? '，模式${s.mode}' : ''}',
      );
      if (s.subjects.isNotEmpty) {
        final subjectText = s.subjects.entries
            .take(6)
            .map((e) => '${e.key}${e.value.toStringAsFixed(0)}')
            .join('；');
        buffer.writeln('  单科：$subjectText');
      }
    }
    buffer.writeln('请确保回答条理清晰，并明确列出可执行要点。');
    return buffer.toString();
  }

  String _apiKeyStorageKey(String userId) => 'deepseek_api_key_$userId';
  String _analysisStorageKey(String userId) => 'deepseek_analysis_$userId';

  Future<void> _persistAnalysis(String content, DateTime timestamp) async {
    final scope = AuthScope.of(context);
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'content': content,
      'updatedAt': timestamp.toIso8601String(),
    });
    await prefs.setString(_analysisStorageKey(scope.session.user.userId), payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 成绩分析'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'DeepSeek 密钥',
              subtitle: '仅保存在本地设备',
              child: Column(
                children: [
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saveKey,
                          child: const Text('保存密钥'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const TagChip(label: '不会上传到服务器'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: '近期成绩',
              subtitle: '来自“高考信息”页的本地记录',
              child: _snapshots.isEmpty
                  ? const Text('暂无成绩记录，请先录入。')
                  : Column(
                      children: _snapshots
                          .map(
                            (s) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${s.formattedDate} ${s.label}',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        '${s.total.toStringAsFixed(0)} 分',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF2C5BF0),
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (s.rank != null) TagChip(label: '省排名 ${s.rank}'),
                                      if (s.mode != null && s.mode!.isNotEmpty) TagChip(label: s.mode!),
                                      ...s.subjects.entries
                                          .take(6)
                                          .map((e) => TagChip(label: '${e.key} ${e.value.toStringAsFixed(0)}')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'AI 分析建议',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_analysisUpdatedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '最近生成：${_analysisUpdatedAt!.toLocal().toString().split(".").first}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7C8698)),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _runAnalysis,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isLoading ? '生成中...' : '生成 AI 分析'),
                  ),
                  const SizedBox(height: 16),
                  if (_analysis != null)
                    MarkdownBody(
                      data: _analysis!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  if (_analysis == null && _error == null)
                    const Text(
                      '点击上方按钮让 DeepSeek 针对最近成绩提供个性化建议。',
                      style: TextStyle(color: Color(0xFF7C8698)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSnapshot {
  const _ScoreSnapshot({
    required this.label,
    required this.total,
    required this.createdAt,
    this.rank,
    this.mode,
    required this.subjects,
  });

  final String label;
  final double total;
  final DateTime createdAt;
  final int? rank;
  final String? mode;
  final Map<String, double> subjects;

  String get formattedDate => createdAt.toIso8601String().split('T').first;

  static List<_ScoreSnapshot> parse(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final List<_ScoreSnapshot> items = [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final map = entry.map((k, v) => MapEntry(k.toString(), v));
        final total = _tryDouble(map, [
          'TOTAL_SCORE',
          'totalScore',
          'SCORE',
          'score',
          'SUM_SCORE',
          'sumScore',
        ]);
        if (total == null) continue;
        final createdAt = _tryDate(map) ?? DateTime.now();
        final rank = _tryInt(map, [
          'RANK_IN_PROVINCE',
          'rankInProvince',
          'rank',
          'minRank',
          'provinceRank',
        ]);
        final mode = map['EXAM_MODE'] ?? map['examMode'];
        final nameCandidate = (map['MOCK_EXAM_NAME'] ?? map['mockExamName'] ?? '').toString().trim();
        final examYear = (map['EXAM_YEAR'] ?? map['examYear'])?.toString();
        final label = nameCandidate.isNotEmpty
            ? nameCandidate
            : (examYear != null && examYear.isNotEmpty ? '高考$examYear' : '考试');

        final subjects = <String, double>{};
        final detailsRaw = map['SCORE_DETAILS'] ?? map['scoreDetails'];
        if (detailsRaw is Map) {
          detailsRaw.forEach((key, value) {
            final d = double.tryParse(value?.toString() ?? '');
            if (d != null) {
              subjects[key.toString()] = d;
            }
          });
        }

        items.add(
          _ScoreSnapshot(
            label: label,
            total: total,
            createdAt: createdAt,
            rank: rank,
            mode: mode?.toString(),
            subjects: subjects,
          ),
        );
      }
    } catch (_) {
      return const [];
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(6).toList();
  }

  static double? _tryDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _tryInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static DateTime? _tryDate(Map<String, dynamic> map) {
    final candidates = [
      map['CREATED_AT'],
      map['createdAt'],
      map['UPDATED_AT'],
      map['updatedAt'],
    ];
    for (final value in candidates) {
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    final year = int.tryParse((map['EXAM_YEAR'] ?? map['examYear'])?.toString() ?? '');
    return year != null ? DateTime(year) : null;
  }
}
