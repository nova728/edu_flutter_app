import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zygc_flutter_prototype/src/state/auth_scope.dart';
import 'package:zygc_flutter_prototype/src/services/api_client.dart';
import 'package:zygc_flutter_prototype/src/models/auth_models.dart';

import 'package:zygc_flutter_prototype/src/widgets/section_card.dart';
import 'package:zygc_flutter_prototype/src/widgets/tag_chip.dart';
import 'analysis_page.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({
    super.key,
    required this.onEditProfile,
    required this.onViewPreferences,
    required this.onViewAnalysis,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onViewPreferences;
  final VoidCallback onViewAnalysis;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final ApiClient _client = ApiClient();
  Future<List<StudentScore>>? _scoresFuture;
  late AuthSession _session;
  bool _initialized = false;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  // 表单状态
  int _selectedCategory = 0; // 0=普通类, 1=艺术类, 2=高职, 3=自招
  bool _isNewGaokao = true; // true=新高考, false=旧高考
  String _examType = '高考成绩';
  bool _isBachelor = true;
  
  // 旧高考：文理科选择
  bool _isScience = true; // true=理科, false=文科
  
  // 新高考：选考科目
  final Set<String> _selectedSubjects = {};
  final Map<String, TextEditingController> _subjectScoreControllers = {
    '物理': TextEditingController(),
    '化学': TextEditingController(),
    '生物': TextEditingController(),
    '政治': TextEditingController(),
    '历史': TextEditingController(),
    '地理': TextEditingController(),
  };
  
  // 基础成绩
  final TextEditingController _totalScoreController = TextEditingController();
  final TextEditingController _rankController = TextEditingController();
  final TextEditingController _chineseController = TextEditingController();
  final TextEditingController _mathController = TextEditingController();
  final TextEditingController _englishController = TextEditingController();
  
  // 旧高考：文综/理综
  final TextEditingController _comprehensiveController = TextEditingController();
  
  final TextEditingController _schoolController = TextEditingController();

  // 本地存储的成绩记录
  List<StudentScore> _localScores = [];

  @override
  void initState() {
    super.initState();
    // 监听成绩变化，自动计算总分
    _chineseController.addListener(_calculateTotalScore);
    _mathController.addListener(_calculateTotalScore);
    _englishController.addListener(_calculateTotalScore);
    _comprehensiveController.addListener(_calculateTotalScore);
    
    // 为每个选考科目添加监听
    _subjectScoreControllers.forEach((subject, controller) {
      controller.addListener(_calculateTotalScore);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final scope = AuthScope.of(context);
    _session = scope.session;
    _initialized = true;
    
    // 加载用户学校信息
    _schoolController.text = _session.user.schoolName ?? '';
  }

  /// 自动计算总分
  void _calculateTotalScore() {
    final chinese = int.tryParse(_chineseController.text) ?? 0;
    final math = int.tryParse(_mathController.text) ?? 0;
    final english = int.tryParse(_englishController.text) ?? 0;
    
    int total = chinese + math + english;
    
    if (_isNewGaokao) {
      // 新高考：累加选考科目成绩
      _selectedSubjects.forEach((subject) {
        final score = int.tryParse(_subjectScoreControllers[subject]?.text ?? '') ?? 0;
        total += score;
      });
    } else {
      // 旧高考：加上文综/理综成绩
      final comprehensive = int.tryParse(_comprehensiveController.text) ?? 0;
      total += comprehensive;
    }
    
    if (total > 0) {
      _totalScoreController.text = total.toString();
    }
  }

  @override
  void dispose() {
    _totalScoreController.dispose();
    _rankController.dispose();
    _chineseController.dispose();
    _mathController.dispose();
    _englishController.dispose();
    _comprehensiveController.dispose();
    _schoolController.dispose();
    _subjectScoreControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  /// 切换高考类型
  void _toggleGaokaoType(bool isNew) {
    setState(() {
      _isNewGaokao = isNew;
      // 切换时清空相关成绩
      if (isNew) {
        _comprehensiveController.clear();
      } else {
        _selectedSubjects.clear();
        _subjectScoreControllers.forEach((_, controller) => controller.clear());
      }
      _totalScoreController.clear();
    });
  }

  /// 切换选考科目（新高考）
  void _toggleSubject(String subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
        _subjectScoreControllers[subject]?.clear();
      } else {
        if (_selectedSubjects.length < 3) {
          _selectedSubjects.add(subject);
        } else {
          _showWarning('最多选择3门科目');
        }
      }
      _calculateTotalScore();
    });
  }

  /// 表单验证
  bool _validateForm() {
    // 验证总分和位次
    if (_totalScoreController.text.isEmpty || _rankController.text.isEmpty) {
      _showWarning('请填写总分和位次');
      return false;
    }

    final totalScore = int.tryParse(_totalScoreController.text);
    if (totalScore == null || totalScore < 0 || totalScore > 750) {
      _showWarning('总分应在 0-750 之间');
      return false;
    }

    final rank = int.tryParse(_rankController.text);
    if (rank == null || rank <= 0) {
      _showWarning('位次必须是正整数');
      return false;
    }

    if (_isNewGaokao) {
      // 新高考验证
      if (_selectedSubjects.length != 3) {
        _showWarning('请选择3门选考科目');
        return false;
      }

      // 验证选考科目成绩
      for (var subject in _selectedSubjects) {
        final scoreText = _subjectScoreControllers[subject]?.text ?? '';
        if (scoreText.isEmpty) {
          _showWarning('请填写 $subject 成绩');
          return false;
        }
        final score = int.tryParse(scoreText);
        if (score == null || score < 0 || score > 100) {
          _showWarning('$subject 成绩应在 0-100 之间');
          return false;
        }
      }
    } else {
      // 旧高考验证
      if (_comprehensiveController.text.isEmpty) {
        _showWarning('请填写${_isScience ? "理综" : "文综"}成绩');
        return false;
      }
      final comprehensive = int.tryParse(_comprehensiveController.text);
      if (comprehensive == null || comprehensive < 0 || comprehensive > 300) {
        _showWarning('${_isScience ? "理综" : "文综"}成绩应在 0-300 之间');
        return false;
      }
    }

    // 验证三大主科成绩
    if (_chineseController.text.isNotEmpty) {
      final chinese = int.tryParse(_chineseController.text);
      if (chinese == null || chinese < 0 || chinese > 150) {
        _showWarning('语文成绩应在 0-150 之间');
        return false;
      }
    }

    if (_mathController.text.isNotEmpty) {
      final math = int.tryParse(_mathController.text);
      if (math == null || math < 0 || math > 150) {
        _showWarning('数学成绩应在 0-150 之间');
        return false;
      }
    }

    if (_englishController.text.isNotEmpty) {
      final english = int.tryParse(_englishController.text);
      if (english == null || english < 0 || english > 150) {
        _showWarning('英语成绩应在 0-150 之间');
        return false;
      }
    }

    return true;
  }

  /// 提交成绩信息（暂时只存储到本地）
  void _submitInfo() {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 模拟提交延迟
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // 构建成绩数据
        final categoryMap = ['普通类', '艺术类', '高职', '自招'];
        
        Map<String, dynamic> scoreDetails = {
          '语文': _chineseController.text.isEmpty ? null : int.parse(_chineseController.text),
          '数学': _mathController.text.isEmpty ? null : int.parse(_mathController.text),
          '英语': _englishController.text.isEmpty ? null : int.parse(_englishController.text),
        };

        String examMode;
        if (_isNewGaokao) {
          examMode = '新高考(3+3)';
          // 添加选考科目成绩
          _selectedSubjects.forEach((subject) {
            scoreDetails[subject] = int.parse(_subjectScoreControllers[subject]?.text ?? '0');
          });
        } else {
          examMode = _isScience ? '旧高考(理科)' : '旧高考(文科)';
          scoreDetails[_isScience ? '理综' : '文综'] = 
              int.parse(_comprehensiveController.text);
        }

        // 创建新的成绩记录
        final newScore = StudentScore(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          examYear: DateTime.now().year,
          totalScore: int.parse(_totalScoreController.text),
          province: _session.user.province ?? '未设置',
          rankInProvince: int.parse(_rankController.text),
          category: categoryMap[_selectedCategory],
          examMode: examMode,
          degreeType: _isBachelor ? '本科' : '专科',
          scoreDetails: scoreDetails,
          selectedSubjects: _isNewGaokao ? _selectedSubjects.toList() : null,
          schoolName: _schoolController.text,
          createdAt: DateTime.now().toString(),
        );

        setState(() {
          _localScores.insert(0, newScore); // 添加到列表开头
          _isSubmitting = false;
        });

        _showSuccess('成绩信息保存成功！');
        _resetForm();
      } catch (e) {
        setState(() {
          _isSubmitting = false;
        });
        _showError('保存失败: ${e.toString()}');
      }
    });
  }

  /// 删除成绩记录
  void _deleteScore(String scoreId) async {
    final confirmed = await _showConfirmDialog(
      '确认删除',
      '确定要删除这条成绩记录吗？',
    );

    if (!confirmed) return;

    setState(() {
      _localScores.removeWhere((score) => score.id == scoreId);
    });
    _showSuccess('删除成功');
  }

  /// 重置表单
  void _resetForm() {
    _totalScoreController.clear();
    _rankController.clear();
    _chineseController.clear();
    _mathController.clear();
    _englishController.clear();
    _comprehensiveController.clear();
    _subjectScoreControllers.forEach((_, controller) => controller.clear());
    setState(() {
      _selectedSubjects.clear();
      _selectedCategory = 0;
      _isBachelor = true;
    });
  }

  /// 显示确认对话框
  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 显示成功提示
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示警告提示
  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.user;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: '完善高考信息',
              subtitle: '补全信息，提升推荐准确度',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x142C5BF0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '已录入 ${_localScores.length} 条',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C5BF0),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分类标签
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0x0F2C5BF0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _CategoryTab(
                          label: '普通类',
                          isSelected: _selectedCategory == 0,
                          onTap: () => setState(() => _selectedCategory = 0),
                        ),
                        _CategoryTab(
                          label: '艺术类',
                          isSelected: _selectedCategory == 1,
                          onTap: () => setState(() => _selectedCategory = 1),
                        ),
                        _CategoryTab(
                          label: '高职',
                          isSelected: _selectedCategory == 2,
                          onTap: () => setState(() => _selectedCategory = 2),
                        ),
                        _CategoryTab(
                          label: '自招',
                          isSelected: _selectedCategory == 3,
                          onTap: () => setState(() => _selectedCategory = 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 高考类型选择
                  _FormSection(
                    label: '高考模式',
                    isRequired: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ToggleButton(
                            label: '新高考',
                            subtitle: '3+3选考',
                            isSelected: _isNewGaokao,
                            onTap: () => _toggleGaokaoType(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ToggleButton(
                            label: '旧高考',
                            subtitle: '文/理综',
                            isSelected: !_isNewGaokao,
                            onTap: () => _toggleGaokaoType(false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 高考地区
                  _FormSection(
                    label: '高考地区',
                    isRequired: true,
                    child: _FieldDisplay(
                      value: user.province ?? '未设置',
                      onTap: () {
                        _showWarning('切换地区功能开发中');
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 所属年级
                  _FormSection(
                    label: '所属年级',
                    isRequired: true,
                    child: _FieldDisplay(
                      value: '高三 (${DateTime.now().year + 1} 年高考)',
                      onTap: () {
                        _showWarning('修改年级功能开发中');
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 成绩类型
                  _FormSection(
                    label: '成绩类型',
                    isRequired: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: _SimpleToggleButton(
                            label: '本科',
                            isSelected: _isBachelor,
                            onTap: () => setState(() => _isBachelor = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SimpleToggleButton(
                            label: '专科',
                            isSelected: !_isBachelor,
                            onTap: () => setState(() => _isBachelor = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 毕业高中
                  _FormSection(
                    label: '毕业高中',
                    isRequired: true,
                    child: TextField(
                      controller: _schoolController,
                      decoration: InputDecoration(
                        hintText: '请输入高中名称',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 根据高考类型显示不同的科目选择
                  if (_isNewGaokao) ...[
                    // 新高考：选考科目
                    _FormSection(
                      label: '选考科目',
                      isRequired: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SubjectButton(
                                label: '物理',
                                isSelected: _selectedSubjects.contains('物理'),
                                onTap: () => _toggleSubject('物理'),
                              ),
                              _SubjectButton(
                                label: '化学',
                                isSelected: _selectedSubjects.contains('化学'),
                                onTap: () => _toggleSubject('化学'),
                              ),
                              _SubjectButton(
                                label: '生物',
                                isSelected: _selectedSubjects.contains('生物'),
                                onTap: () => _toggleSubject('生物'),
                              ),
                              _SubjectButton(
                                label: '政治',
                                isSelected: _selectedSubjects.contains('政治'),
                                onTap: () => _toggleSubject('政治'),
                              ),
                              _SubjectButton(
                                label: '历史',
                                isSelected: _selectedSubjects.contains('历史'),
                                onTap: () => _toggleSubject('历史'),
                              ),
                              _SubjectButton(
                                label: '地理',
                                isSelected: _selectedSubjects.contains('地理'),
                                onTap: () => _toggleSubject('地理'),
                              ),
                            ],
                          ),
                          if (_selectedSubjects.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                '已选择: ${_selectedSubjects.join('、')} (${_selectedSubjects.length}/3)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedSubjects.length == 3
                                      ? const Color(0xFF2C5BF0)
                                      : const Color(0xFF7C8698),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 旧高考：文理科选择
                    _FormSection(
                      label: '科类',
                      isRequired: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: _SimpleToggleButton(
                              label: '理科',
                              isSelected: _isScience,
                              onTap: () {
                                setState(() {
                                  _isScience = true;
                                  _comprehensiveController.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SimpleToggleButton(
                              label: '文科',
                              isSelected: !_isScience,
                              onTap: () {
                                setState(() {
                                  _isScience = false;
                                  _comprehensiveController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 成绩输入
                  Text(
                    '成绩详情',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424A59),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 总分
                  _FormSection(
                    label: '总分',
                    isRequired: true,
                    child: TextField(
                      controller: _totalScoreController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '自动计算或手动输入 (0-750)',
                        suffixText: '分',
                        suffixIcon: const Icon(Icons.calculate_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 位次
                  _FormSection(
                    label: '省排名',
                    isRequired: true,
                    child: TextField(
                      controller: _rankController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '请输入省内位次',
                        suffixText: '名',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 三大主科成绩
                  Row(
                    children: [
                      Expanded(
                        child: _FormSection(
                          label: '语文',
                          child: TextField(
                            controller: _chineseController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: '0-150',
                              suffixText: '分',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FormSection(
                          label: '数学',
                          child: TextField(
                            controller: _mathController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              hintText: '0-150',
                              suffixText: '分',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _FormSection(
                    label: '英语',
                    child: TextField(
                      controller: _englishController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0-150',
                        suffixText: '分',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 根据高考类型显示不同的成绩输入
                  if (_isNewGaokao) ...[
                    // 新高考：选考科目成绩（每科100分）
                    if (_selectedSubjects.isNotEmpty) ...[
                      Text(
                        '选考科目成绩',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF424A59),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._selectedSubjects.map((subject) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FormSection(
                            label: subject,
                            isRequired: true,
                            child: TextField(
                              controller: _subjectScoreControllers[subject],
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: '0-100',
                                suffixText: '分',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Color(0xFFFF9800),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '请先选择3门选考科目',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFF9800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // 旧高考：文综/理综（300分）
                    _FormSection(
                      label: _isScience ? '理综' : '文综',
                      isRequired: true,
                      child: TextField(
                        controller: _comprehensiveController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: '0-300',
                          suffixText: '分',
                          helperText: _isScience ? '物理+化学+生物' : '政治+历史+地理',
                          helperStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C8698),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 提交和重置按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _resetForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(
                              color: Color(0xFFD3D9E5),
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            '重置',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C5BF0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '保存信息',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 历史成绩记录
            if (_localScores.isNotEmpty) ...[
              SectionCard(
                title: '成绩记录',
                subtitle: '本地存储的成绩记录',
                trailing: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      // 刷新显示
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('刷新'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2C5BF0),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _localScores.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final score = _localScores[index];
                    return _ScoreRecordCard(
                      score: score,
                      onDelete: () => _deleteScore(score.id ?? ''),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 操作按钮
            SectionCard(
              title: '更多操作',
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.analytics_outlined,
                    label: '查看成绩分析',
                    subtitle: '深入了解您的成绩水平',
                    onTap: widget.onViewAnalysis,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: '编辑个人资料',
                    subtitle: '修改基本信息',
                    onTap: widget.onEditProfile,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.settings_outlined,
                    label: '志愿偏好设置',
                    subtitle: '自定义推荐条件',
                    onTap: widget.onViewPreferences,
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

// 成绩记录卡片
class _ScoreRecordCard extends StatelessWidget {
  const _ScoreRecordCard({
    required this.score,
    required this.onDelete,
  });

  final StudentScore score;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0F2C5BF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE3E8EF),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C5BF0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${score.examYear}年',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: score.examMode?.contains('新高考') == true
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  score.examMode ?? '-',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: score.examMode?.contains('新高考') == true
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57C00),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                score.province,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7C8698),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: const Color(0xFFF04F52),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '删除记录',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '总分',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C8698),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${score.totalScore}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5BF0),
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '省排名',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C8698),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      score.rankLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF424A59),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // 显示各科成绩
          if (score.scoreDetails != null && score.scoreDetails!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: score.scoreDetails!.entries.map((entry) {
                if (entry.value == null) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE3E8EF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424A59),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          const SizedBox(height: 12),
          Text(
            '录入时间: ${score.createdAtLabel}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB0B8C7),
            ),
          ),
        ],
      ),
    );
  }
}

// 操作按钮
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFD3D9E5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x0F2C5BF0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2C5BF0),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424A59),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7C8698),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFB0B8C7),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2C5BF0).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF2C5BF0)
                  : const Color(0xFF7C8698),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final Widget child;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF424A59),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Color(0xFFF04F52),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _FieldDisplay extends StatelessWidget {
  const _FieldDisplay({
    this.label,
    required this.value,
    required this.onTap,
  });

  final String? label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x0F2C5BF0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label != null ? '$label$value' : value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF424A59),
                ),
              ),
            ),
            const Text(
              '修改',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C5BF0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF9500) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFD3D9E5),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF9500).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF424A59),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected 
                      ? Colors.white.withOpacity(0.9)
                      : const Color(0xFF7C8698),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SimpleToggleButton extends StatelessWidget {
  const _SimpleToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C5BF0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFD3D9E5),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF424A59),
          ),
        ),
      ),
    );
  }
}

class _SubjectButton extends StatelessWidget {
  const _SubjectButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1F2C5BF0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2C5BF0)
                : const Color(0xFFD3D9E5),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2C5BF0).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFF2C5BF0)
                : const Color(0xFF424A59),
          ),
        ),
      ),
    );
  }
}

class StudentScore {
  const StudentScore({
    this.id,
    required this.examYear,
    required this.totalScore,
    required this.province,
    this.rankInProvince,
    this.category,
    this.examMode,
    this.degreeType,
    this.scoreDetails,
    this.selectedSubjects,
    this.schoolName,
    this.createdAt,
  });

  final String? id;
  final int examYear;
  final int totalScore;
  final String province;
  final int? rankInProvince;
  final String? category;
  final String? examMode; // 新高考(3+3) 或 旧高考(理科/文科)
  final String? degreeType;
  final Map<String, dynamic>? scoreDetails; // 各科成绩详情
  final List<String>? selectedSubjects; // 选考科目
  final String? schoolName;
  final String? createdAt;

  factory StudentScore.fromJson(Map<String, dynamic> json) {
    return StudentScore(
      id: json['ID']?.toString(),
      examYear: int.tryParse(json['EXAM_YEAR']?.toString() ?? '') ?? 0,
      totalScore: int.tryParse(json['TOTAL_SCORE']?.toString() ?? '') ?? 0,
      province: json['PROVINCE']?.toString() ?? '-',
      rankInProvince: int.tryParse(json['RANK_IN_PROVINCE']?.toString() ?? ''),
      category: json['CATEGORY']?.toString(),
      examMode: json['EXAM_MODE']?.toString(),
      degreeType: json['DEGREE_TYPE']?.toString(),
      scoreDetails: json['SCORE_DETAILS'] as Map<String, dynamic>?,
      selectedSubjects: (json['SELECTED_SUBJECTS'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      schoolName: json['SCHOOL_NAME']?.toString(),
      createdAt: json['CREATED_AT']?.toString(),
    );
  }

  String get rankLabel =>
      rankInProvince == null ? '未提供' : rankInProvince.toString();
  String get createdAtLabel => (createdAt ?? '-').split(' ').first;
}