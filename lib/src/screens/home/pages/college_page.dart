import 'package:flutter/material.dart';

import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    _tabController = TabController(length: 2, vsync: this);
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
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _CollegeLibraryTab(),
              _SchoolRecordsTab(),
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
  
  final List<CollegeSummary> _colleges = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize = 10;
  
  String? _selectedProvince;
  bool _only985 = false;
  bool _only211 = false;
  bool _onlyDFC = false;
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

  Future<Set<String>> _getFavoriteNames() async {
    final scope = AuthScope.of(context);
    final key = 'favorites_${scope.session.user.userId}';
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list
          .map((e) => e['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
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
    if (!mounted) return;

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
      
      // 修复省份筛选：规范化省份名称
      if (_selectedProvince != null) {
        // 移除省份名称中的后缀（省、市、自治区等）
        final normalizedProvince = _normalizeProvince(_selectedProvince!);
        query['province'] = normalizedProvince;
      }
      
      if (_only985) query['is985'] = '1';
      if (_only211) query['is211'] = '1';
      if (_onlyDFC) query['isDFC'] = '1';

      final response = await _client.get('/colleges', query: query);
      var rows = response['data'] as List? ?? const [];
      
      // 如果后端返回的数据为空且有省份筛选，尝试客户端过滤
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
      final favoriteNames = await _getFavoriteNames();
      final newlyFavIds = newColleges
          .where((c) => favoriteNames.contains(c.collegeName))
          .map((c) => c.collegeCode);

      if (!mounted) return;
      setState(() {
        _favoriteCollegeIds.addAll(newlyFavIds);
        _colleges.addAll(newColleges);
        _currentPage++;
        _hasMore = newColleges.length >= _pageSize;
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

  /// 规范化省份名称：移除后缀（省、市、自治区等）
  String _normalizeProvince(String input) {
    var result = input.trim();
    
    // 定义所有可能的后缀
    const suffixes = [
      '特别行政区',
      '维吾尔自治区',
      '壮族自治区',
      '回族自治区',
      '自治区',
      '省',
      '市',
    ];
    
    // 移除匹配的后缀
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
      // 在打开弹窗前获取 token
      final scope = AuthScope.of(context);
      final token = scope.session.token;
      
      final detail = await _client.get('/colleges/${summary.collegeCode}');
      if (!mounted) return;
      final data = detail['data'] as Map<String, dynamic>? ?? {};
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _CollegeDetailSheet(
          summary: summary,
          detailData: data,
          client: _client,
          token: token,
          userProvince: scope.session.user.province,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('院校详情加载失败')),
      );
    }
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
                        initialValue: _selectedProvince,
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
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('仅显示 211 院校'),
                        value: _only211,
                        onChanged: (value) {
                          setState(() {
                            _only211 = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('仅显示 双一流 院校'),
                        value: _onlyDFC,
                        onChanged: (value) {
                          setState(() {
                            _onlyDFC = value;
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
                                  _only211 = false;
                                  _onlyDFC = false;
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
                      onTap: () => _openCollegeDetail(college),
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
    _recordsFuture = _fetchRecords();
    _initialized = true;
  }

  Future<List<SchoolEnrollmentRecord>> _fetchRecords() async {
    if (_token == null || _token!.isEmpty) {
      return const [];
    }
    final query = <String, String>{};
    final collegeName = _schoolController.text.trim();
    if (collegeName.isNotEmpty) {
      query['schoolName'] = collegeName;
    }
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
                    labelText: '院校名称（可选）',
                    hintText: '不填则查询全部院校记录',
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


class _CollegeCard extends StatelessWidget {
  const _CollegeCard({
    required this.college,
    this.onTap,
  });

  final CollegeSummary college;
  final VoidCallback? onTap;

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

// 院校详情Sheet组件
class _CollegeDetailSheet extends StatefulWidget {
  const _CollegeDetailSheet({
    required this.summary,
    required this.detailData,
    required this.client,
    required this.token,
    this.userProvince,
  });

  final CollegeSummary summary;
  final Map<String, dynamic> detailData;
  final ApiClient client;
  final String token;
  final String? userProvince; 

  @override
  State<_CollegeDetailSheet> createState() => _CollegeDetailSheetState();
}

class _CollegeDetailSheetState extends State<_CollegeDetailSheet>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<AdmissionRecord>? _admissionRecords;
  bool _isLoadingAdmissions = false;
  String? _selectedProvince;
  int? _selectedYear;
  bool _provinceInitialized = false;
  List<PlanItem>? _planItems;
  bool _isLoadingPlans = false;
  int? _selectedPlanYear;
  String _normalizeProvinceShort(String input) {
    var result = input.trim();
    const suffixes = [
      '特别行政区', '维吾尔自治区', '壮族自治区', '回族自治区', '自治区', '省', '市'
    ];
    for (final s in suffixes) {
      if (result.endsWith(s)) {
        result = result.substring(0, result.length - s.length);
        break;
      }
    }
    return result;
  }

  // 完整的省份列表
  static const List<String> _provinces = [
    '北京', '天津', '河北', '山西', '内蒙古',
    '辽宁', '吉林', '黑龙江', '上海', '江苏',
    '浙江', '安徽', '福建', '江西', '山东',
    '河南', '湖北', '湖南', '广东', '广西',
    '海南', '重庆', '四川', '贵州', '云南',
    '西藏', '陕西', '甘肃', '青海', '宁夏',
    '新疆', '香港', '澳门', '台湾',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _admissionRecords == null) {
        _loadAdmissionRecords();
      } else if (_tabController.index == 2 && _planItems == null) {
        _loadPlans();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmissionRecords() async {
    if (widget.token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
      }
      return;
    }

    setState(() {
      _isLoadingAdmissions = true;
    });

    try {
      final query = <String, String>{};
      if (_selectedProvince != null) query['province'] = _selectedProvince!;
      if (_selectedYear != null) query['year'] = _selectedYear.toString();

      final response = await widget.client.get(
        '/colleges/${widget.summary.collegeCode}/admissions',
        headers: {'Authorization': 'Bearer ${widget.token}'}, // 使用 widget.token
        query: query,
      );

      final records = (response['data'] as List?)
          ?.map((e) => AdmissionRecord.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

      setState(() {
        _admissionRecords = records;
        _isLoadingAdmissions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAdmissions = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载录取数据失败: $e')),
        );
      }
    }
  }

  Future<void> _loadPlans() async {
    setState(() { _isLoadingPlans = true; });
    try {
      final query = <String, String>{ 'collegeCode': widget.summary.collegeCode.toString() };
      if (_selectedPlanYear != null) query['year'] = _selectedPlanYear.toString();
      final resp = await widget.client.get('/plans', query: query);
      final rows = (resp['data'] as List?) ?? const [];
      setState(() {
        _planItems = rows.map((e) => PlanItem.fromJson(e as Map<String, dynamic>)).toList();
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() { _isLoadingPlans = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载招生计划失败: $e')));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provinceInitialized) return;
    final prov = widget.userProvince;
    if (prov != null && prov.isNotEmpty) {
      final short = _normalizeProvinceShort(prov);
      if (_provinces.contains(short)) {
        _selectedProvince = short;
      }
    }
    _provinceInitialized = true;
  }


  @override
  Widget build(BuildContext context) {

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // 拖动指示器
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3D9E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.summary.collegeName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1F2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '院校代码：${widget.summary.collegeCode}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7C8698),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F7FB),
                    ),
                  ),
                ],
              ),
            ),

            // Tab栏
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8ECF4), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2C5BF0),
                unselectedLabelColor: const Color(0xFF7C8698),
                indicatorColor: const Color(0xFF2C5BF0),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: '院校信息'),
                  Tab(text: '历年录取'),
                  Tab(text: '招生计划'),
                ],
              ),
            ),

            // 内容区
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      _DetailRow(
                        label: '所在省份',
                        value: widget.detailData['PROVINCE']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: '所在城市',
                        value: widget.detailData['CITY_NAME']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: '院校类型',
                        value: widget.detailData['COLLEGE_TYPE']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: '院校标签',
                        value: [
                          if (widget.summary.is985) '985',
                          if (widget.summary.is211) '211',
                          if (widget.summary.isDoubleFirstClass) '双一流',
                        ].join(' · '),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox.shrink(),
                    ],
                  ),

                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F7FB),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE8ECF4)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '筛选条件',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF424A59),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String?>(
                                    initialValue: _selectedProvince,
                                    decoration: const InputDecoration(
                                      labelText: '省份',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('全部'),
                                      ),
                                      ..._provinces.map(
                                        (province) => DropdownMenuItem(
                                          value: province,
                                          child: Text(province),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedProvince = value;
                                      });
                                      _loadAdmissionRecords();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: _selectedYear,
                                    decoration: const InputDecoration(
                                      labelText: '年份',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text('全部'),
                                      ),
                                      for (int year = DateTime.now().year - 1;
                                          year >= 2017;
                                          year--)
                                        DropdownMenuItem(
                                          value: year,
                                          child: Text(year.toString()),
                                        ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedYear = value;
                                      });
                                      _loadAdmissionRecords();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: _isLoadingAdmissions
                            ? const Center(child: CircularProgressIndicator())
                            : _admissionRecords == null
                                ? const Center(
                                    child: Text('加载中...'),
                                  )
                                : _admissionRecords!.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inbox_outlined,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '暂无录取数据',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _admissionRecords!.length,
                                        itemBuilder: (context, index) {
                                          final record =
                                              _admissionRecords![index];
                                          return _AdmissionRecordCard(
                                            record: record,
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F7FB),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE8ECF4)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                initialValue: _selectedPlanYear,
                                decoration: const InputDecoration(
                                  labelText: '年份',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('全部')),
                                  for (int year = DateTime.now().year; year >= 2017; year--)
                                    DropdownMenuItem(value: year, child: Text(year.toString())),
                                ],
                                onChanged: (value) {
                                  setState(() { _selectedPlanYear = value; });
                                  _loadPlans();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoadingPlans
                            ? const Center(child: CircularProgressIndicator())
                            : (_planItems == null
                                ? const Center(child: Text('加载中...'))
                                : _planItems!.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                                            const SizedBox(height: 16),
                                            Text('暂无招生计划', style: TextStyle(color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _planItems!.length,
                                        itemBuilder: (context, index) {
                                          final item = _planItems![index];
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
                                                Text(item.majorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1F2E))),
                                                const SizedBox(height: 8),
                                                Row(children: [
                                                  Expanded(child: _InfoItem(icon: Icons.calendar_today, label: '年份', value: item.admissionYear.toString())),
                                                  Expanded(child: _InfoItem(icon: Icons.location_on, label: '省份', value: item.province)),
                                                ]),
                                                const SizedBox(height: 8),
                                                Row(children: [
                                                  Expanded(child: _InfoItem(icon: Icons.people_alt, label: '计划人数', value: item.planCountLabel, valueColor: const Color(0xFF2C5BF0))),
                                                  Expanded(child: _InfoItem(icon: Icons.description, label: '说明', value: item.description ?? '-')),
                                                ]),
                                              ],
                                            ),
                                          );
                                        },
                                      ))
                      ),
                    ],
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

// 录取记录卡片
class _AdmissionRecordCard extends StatelessWidget {
  const _AdmissionRecordCard({required this.record});

  final AdmissionRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECF4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.majorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1F2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: record.type == '理科'
                      ? const Color(0xFFE3F2FD)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: record.type == '理科'
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFF57C00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.calendar_today,
                  label: '年份',
                  value: record.admissionYear.toString(),
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.location_on,
                  label: '省份',
                  value: record.province,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.score,
                  label: '最低分',
                  value: record.minScore,
                  valueColor: const Color(0xFF2C5BF0),
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.trending_up,
                  label: '最低位次',
                  value: record.minRank.toString(),
                  valueColor: const Color(0xFF21B573),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 信息项组件
class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7C8698)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF7C8698),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF424A59),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// 录取记录数据模型
class AdmissionRecord {
  const AdmissionRecord({
    required this.admissionId,
    required this.majorName,
    required this.type,
    required this.province,
    required this.admissionYear,
    required this.minScore,
    required this.minRank,
  });

  final int admissionId;
  final String majorName;
  final String type;
  final String province;
  final int admissionYear;
  final String minScore;
  final int minRank;

  factory AdmissionRecord.fromJson(Map<String, dynamic> json) {
    return AdmissionRecord(
      admissionId: json['ADMISSION_ID'] as int,
      majorName: json['MAJOR_NAME']?.toString() ?? '-',
      type: json['TYPE']?.toString() ?? '-',
      province: json['PROVINCE']?.toString() ?? '-',
      admissionYear: json['ADMISSION_YEAR'] as int,
      minScore: json['MIN_SCORE']?.toString() ?? '-',
      minRank: json['MIN_RANK'] as int? ?? 0,
    );
  }
}

class PlanItem {
  const PlanItem({
    required this.planId,
    required this.collegeCode,
    required this.majorName,
    required this.province,
    required this.admissionYear,
    this.planCount,
    this.description,
  });

  final int planId;
  final int collegeCode;
  final String majorName;
  final String province;
  final int admissionYear;
  final int? planCount;
  final String? description;

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      planId: int.tryParse(json['PLAN_ID']?.toString() ?? '') ?? 0,
      collegeCode: int.tryParse(json['COLLEGE_CODE']?.toString() ?? '') ?? 0,
      majorName: json['MAJOR_NAME']?.toString() ?? '-',
      province: json['PROVINCE']?.toString() ?? '-',
      admissionYear: int.tryParse(json['ADMISSION_YEAR']?.toString() ?? '') ?? 0,
      planCount: int.tryParse(json['PLAN_COUNT']?.toString() ?? ''),
      description: json['DESCRIPTION']?.toString(),
    );
  }

  String get planCountLabel => planCount?.toString() ?? '-';
}
