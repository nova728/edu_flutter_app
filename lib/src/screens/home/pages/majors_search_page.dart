import 'package:flutter/material.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';

class MajorsSearchPage extends StatefulWidget {
  const MajorsSearchPage({super.key});

  @override
  State<MajorsSearchPage> createState() => _MajorsSearchPageState();
}

class _MajorsSearchPageState extends State<MajorsSearchPage> {
  final ApiClient _client = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MajorItem> _majors = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMajors(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMajors();
      }
    }
  }

  Future<void> _loadMajors({bool reset = false}) async {
    if (_isLoading) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _majors.clear();
        _currentPage = 1;
        _hasMore = true;
      }
    });

    try {
      final query = <String, String>{
        'page': _currentPage.toString(),
        'pageSize': _pageSize.toString(),
      };
      final q = _searchController.text.trim();
      if (q.isNotEmpty) query['q'] = q;

      final resp = await _client.get('/majors', query: query);
      final rows = (resp['data'] as List?) ?? const [];
      final newMajors = rows.map((e) => MajorItem.fromJson(e as Map<String, dynamic>)).toList();

      if (!mounted) return;
      setState(() {
        _majors.addAll(newMajors);
        _currentPage++;
        _hasMore = newMajors.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('专业查询'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2430),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '输入专业名称进行查询',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _loadMajors(reset: true);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _loadMajors(reset: true),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _loadMajors(reset: true),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('查询'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _majors.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('暂无专业数据', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => _loadMajors(reset: true), child: const Text('重新加载')),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: _majors.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _majors.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: _isLoading ? const CircularProgressIndicator() : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final major = _majors[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(16),
                          border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE8ECF4))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    major.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1F2E),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    major.type,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              major.intro ?? '-',
                              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4B5769)),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class MajorItem {
  const MajorItem({
    required this.id,
    required this.name,
    required this.type,
    this.intro,
  });

  final int id;
  final String name;
  final String type;
  final String? intro;

  factory MajorItem.fromJson(Map<String, dynamic> json) {
    return MajorItem(
      id: int.tryParse(json['MAJOR_ID']?.toString() ?? '') ?? 0,
      name: json['MAJOR_NAME']?.toString() ?? '-',
      type: json['MAJOR_TYPE']?.toString() ?? '-',
      intro: json['BASE_INTRO']?.toString(),
    );
  }
}