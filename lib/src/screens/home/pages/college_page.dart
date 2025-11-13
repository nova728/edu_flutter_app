import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'favorite_colleges_page.dart';

class CollegePage extends StatefulWidget {
  const CollegePage({super.key});

  @override
  State<CollegePage> createState() => _CollegePageState();
}

class _CollegePageState extends State<CollegePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2C5BF0),
            unselectedLabelColor: const Color(0xFF7C8698),
            indicatorColor: const Color(0xFF2C5BF0),
            indicatorWeight: 3,
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: '全国院校'),
              Tab(text: '高中录取'),
              Tab(text: '我的对比'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _CollegeLibraryTab(),
              _SchoolRecordsTab(),
              _ComparisonTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// 全国院校库标签页
class _CollegeLibraryTab extends StatefulWidget {
  const _CollegeLibraryTab();

  @override
  State<_CollegeLibraryTab> createState() => _CollegeLibraryTabState();
}

class _CollegeLibraryTabState extends State<_CollegeLibraryTab> {
  final ApiClient _client = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<CollegeSummary> _colleges = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  
  String? _selectedProvince;
  bool _only985 = false;
  bool _showFilters = false;

  // 添加收藏集合
  final Set<int> _favoriteCollegeIds = {};

  static const List<String> _provinces = [
    '北京市', '天津市', '河北省', '山西省', '内蒙古自治区',
    '辽宁省', '吉林省', '黑龙江省', '上海市', '江苏省',
    '浙江省', '安徽省', '福建省', '江西省', '山东省',
    '河南省', '湖北省', '湖南省', '广东省', '广西壮族自治区',
    '海南省', '重庆市', '四川省', '贵州省', '云南省',
    '西藏自治区', '陕西省', '甘肃省', '青海省', '宁夏回族自治区',
    '新疆维吾尔自治区',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 添加搜索监听
    _searchController.addListener(_onSearchChanged);
    _loadColleges(reset: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 搜索框内容变化时的回调
  void _onSearchChanged() {
    // 使用防抖，避免频繁请求
    if (_searchController.text.trim().isEmpty) {
      _loadColleges(reset: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadColleges();
      }
    }
  }

  Future<void> _loadColleges({bool reset = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (reset) {
        _colleges.clear();
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final query = <String, String>{
        'pageSize': _pageSize.toString(),
        'page': _currentPage.toString(),
      };
      
      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) query['q'] = keyword;
      if (_selectedProvince != null) query['province'] = _selectedProvince!;
      if (_only985) query['is985'] = '1';

      final response = await _client.get('/colleges', query: query);
      var rows = response['data'] as List? ?? const [];
      
      if (rows.isEmpty && query.containsKey('province')) {
        final fallbackQuery = Map<String, String>.from(query)..remove('province');
        final fallbackResp = await _client.get('/colleges', query: fallbackQuery);
        final normalizedTarget = _normalizeProvince(_selectedProvince!);
        rows = (fallbackResp['data'] as List? ?? const []).where((row) {
          final province = row['PROVINCE']?.toString() ?? '';
          return _normalizeProvince(province) == normalizedTarget;
        }).toList();
      }

      final newColleges = rows.map((e) => CollegeSummary.fromJson(e as Map<String, dynamic>)).toList();
      
      setState(() {
        _colleges.addAll(newColleges);
        _currentPage++;
        _hasMore = newColleges.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  String _normalizeProvince(String input) {
    var result = input.trim();
    const suffixes = ['特别行政区', '维吾尔自治区', '壮族自治区', '回族自治区', '自治区', '省', '市'];
    for (final suffix in suffixes) {
      if (result.endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length);
        break;
      }
    }
    return result;
  }

  Future<void> _openCollegeDetail(CollegeSummary summary) async {
    try {
      final detail = await _client.get('/colleges/${summary.collegeCode}');
      if (!mounted) return;
      final data = detail['data'] as Map<String, dynamic>? ?? {};
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        summary.collegeName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailRow(label: '院校代码', value: summary.collegeCode.toString()),
                const SizedBox(height: 12),
                _DetailRow(label: '所在省份', value: data['PROVINCE']?.toString() ?? '-'),
                const SizedBox(height: 12),
                _DetailRow(label: '所在城市', value: data['CITY_NAME']?.toString() ?? '-'),
                const SizedBox(height: 12),
                _DetailRow(label: '院校类型', value: data['COLLEGE_TYPE']?.toString() ?? '-'),
                const SizedBox(height: 12),
                _DetailRow(
                  label: '院校标签',
                  value: [
                    if (summary.is985) '985',
                    if (summary.is211) '211',
                    if (summary.isDoubleFirstClass) '双一流',
                  ].join(' · '),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.favorite_border_rounded),
                        label: const Text('收藏'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入对比列表')),
                          );
                        },
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: const Text('加入对比'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('院校详情加载失败')),
      );
    }
  }

  void _toggleFavorite(int collegeId, String collegeName) {
    setState(() {
      if (_favoriteCollegeIds.contains(collegeId)) {
        _favoriteCollegeIds.remove(collegeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已取消收藏 $collegeName'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _favoriteCollegeIds.add(collegeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已收藏 $collegeName'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '查看',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FavoriteCollegesPage(),
                  ),
                );
              },
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索和筛选栏
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索院校名称',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _loadColleges(reset: true);
                              },
                            )
                          : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _loadColleges(reset: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                      color: _showFilters ? const Color(0xFF2C5BF0) : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: _showFilters 
                        ? const Color(0x142C5BF0) 
                        : Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showFilters) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String?>(
                        value: _selectedProvince,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('全部省份'),
                          ),
                          ..._provinces.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p,
                              child: Text(p, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProvince = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: '所在省份',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('仅显示 985 院校'),
                        value: _only985,
                        onChanged: (value) {
                          setState(() {
                            _only985 = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _loadColleges(reset: true),
                              child: const Text('应用筛选'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedProvince = null;
                                  _only985 = false;
                                });
                                _loadColleges(reset: true);
                              },
                              child: const Text('重置'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // 院校列表
        Expanded(
          child: _colleges.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无院校数据',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _loadColleges(reset: true),
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                itemCount: _colleges.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _colleges.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  final college = _colleges[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CollegeCard(
                      college: college,
                      isFavorite: _favoriteCollegeIds.contains(college.collegeCode),
                      onTap: () => _openCollegeDetail(college),
                      onFavoriteToggle: () => _toggleFavorite(
                        college.collegeCode,
                        college.collegeName,
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

// 高中录取记录标签页
class _SchoolRecordsTab extends StatefulWidget {
  const _SchoolRecordsTab();

  @override
  State<_SchoolRecordsTab> createState() => _SchoolRecordsTabState();
}

class _SchoolRecordsTabState extends State<_SchoolRecordsTab> {
  final ApiClient _client = ApiClient();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  Future<List<SchoolEnrollmentRecord>>? _recordsFuture;
  String? _token;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final scope = AuthScope.of(context);
    _token = scope.session.token;
    _schoolController.text = scope.session.user.schoolName ?? '';
    _recordsFuture = _fetchRecords();
    _initialized = true;
  }

  Future<List<SchoolEnrollmentRecord>> _fetchRecords() async {
    final schoolName = _schoolController.text.trim();
    if (_token == null || _token!.isEmpty || schoolName.isEmpty) {
      return const [];
    }
    final query = {'schoolName': schoolName};
    final yearText = _yearController.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      if (year != null) query['graduationYear'] = year.toString();
    }
    final response = await _client.get(
      '/school-enrollment',
      headers: {'Authorization': 'Bearer $_token'},
      query: query,
    );
    final rows = response['data'] as List? ?? const [];
    return rows.map((e) => SchoolEnrollmentRecord.fromJson(e)).toList();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        children: [
          SectionCard(
            title: '筛选条件',
            subtitle: '查询高中历年录取数据',
            child: Column(
              children: [
                TextField(
                  controller: _schoolController,
                  decoration: const InputDecoration(
                    labelText: '学校名称',
                    hintText: '输入学校名称（必填）',
                    prefixIcon: Icon(Icons.school_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '毕业年份',
                    hintText: '例如 2024（可选）',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _recordsFuture = _fetchRecords();
                          });
                        },
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('查询'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _yearController.clear();
                            _recordsFuture = _fetchRecords();
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('重置'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: '录取记录',
            subtitle: '高中历年录取院校数据',
            child: FutureBuilder<List<SchoolEnrollmentRecord>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Text('数据加载失败：${snapshot.error}');
                }
                final records = snapshot.data ?? const [];
                if (records.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('暂无记录，请调整筛选条件'),
                    ),
                  );
                }
                return Column(
                  children: records.take(10).map((record) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecordCard(record: record),
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 对比列表标签页
class _ComparisonTab extends StatelessWidget {
  const _ComparisonTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _CompareCard(
            title: '师范类院校对比',
            colleges: ['华东师范大学', '南京师范大学'],
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('对比详情功能开发中')),
              );
            },
          ),
          const SizedBox(height: 16),
          _CompareCard(
            title: '综合类院校对比',
            colleges: ['浙江大学', '上海交通大学'],
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('对比详情功能开发中')),
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('新建对比功能开发中')),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('新建对比'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollegeCard extends StatelessWidget {
  const _CollegeCard({
    required this.college,
    required this.isFavorite,
    this.onTap,
    required this.onFavoriteToggle,
  });

  final CollegeSummary college;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8ECF4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      college.collegeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 收藏按钮带动画效果
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: Icon(
                        isFavorite 
                          ? Icons.favorite_rounded 
                          : Icons.favorite_border_rounded,
                      ),
                      onPressed: onFavoriteToggle,
                      color: isFavorite 
                        ? const Color(0xFFF04F52) 
                        : const Color(0xFF7C8698),
                      iconSize: 20,
                      splashRadius: 24,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (college.is985) const _Tag(label: '985', color: Color(0xFF2C5BF0)),
                  if (college.is211) const _Tag(label: '211', color: Color(0xFFFF9500)),
                  if (college.isDoubleFirstClass) const _Tag(label: '双一流', color: Color(0xFF21B573)),
                  _Tag(label: college.province, color: const Color(0xFF7C8698)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});

  final SchoolEnrollmentRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.collegeName,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(label: '年份', value: record.graduationYearLabel),
              const SizedBox(width: 8),
              _InfoChip(label: '录取', value: record.admissionCountLabel),
              const SizedBox(width: 8),
              _InfoChip(label: '最低分', value: record.minScoreLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.title,
    required this.colleges,
    required this.onTap,
  });

  final String title;
  final List<String> colleges;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8ECF4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, color: Color(0xFF2C5BF0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              ...colleges.map((college) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $college',
                  style: theme.textTheme.bodyMedium,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CollegeSummary {
  const CollegeSummary({
    required this.collegeCode,
    required this.collegeName,
    required this.province,
    this.cityName,
    required this.is985,
    required this.is211,
    required this.isDoubleFirstClass,
  });

  final int collegeCode;
  final String collegeName;
  final String province;
  final String? cityName;
  final bool is985;
  final bool is211;
  final bool isDoubleFirstClass;

  factory CollegeSummary.fromJson(Map<String, dynamic> json) {
    return CollegeSummary(
      collegeCode: int.tryParse(json['COLLEGE_CODE']?.toString() ?? '') ?? 0,
      collegeName: json['COLLEGE_NAME']?.toString() ?? '-',
      province: json['PROVINCE']?.toString() ?? '-',
      cityName: json['CITY_NAME']?.toString(),
      is985: _toBool(json['IS_985']),
      is211: _toBool(json['IS_211']),
      isDoubleFirstClass: _toBool(json['IS_DFC'] ?? json['IS_DOUBLE_FIRST_CLASS']),
    );
  }

  static bool _toBool(Object? value) {
    if (value == null) return false;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true';
  }
}

class SchoolEnrollmentRecord {
  const SchoolEnrollmentRecord({
    required this.collegeName,
    this.graduationYear,
    this.admissionCount,
    this.minScore,
    this.minRank,
  });

  final String collegeName;
  final int? graduationYear;
  final int? admissionCount;
  final int? minScore;
  final int? minRank;

  factory SchoolEnrollmentRecord.fromJson(Map<String, dynamic> json) {
    return SchoolEnrollmentRecord(
      collegeName: json['COLLEGE_NAME']?.toString() ?? '-',
      graduationYear: int.tryParse(json['GRADUATION_YEAR']?.toString() ?? ''),
      admissionCount: int.tryParse(json['ADMISSION_COUNT']?.toString() ?? ''),
      minScore: int.tryParse(json['MIN_SCORE']?.toString() ?? ''),
      minRank: int.tryParse(json['MIN_RANK']?.toString() ?? ''),
    );
  }

  String get graduationYearLabel => graduationYear?.toString() ?? '-';
  String get admissionCountLabel => admissionCount?.toString() ?? '-';
  String get minScoreLabel => minScore?.toString() ?? '-';
  String get minRankLabel => minRank?.toString() ?? '-';
}
