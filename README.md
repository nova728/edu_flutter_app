# 高考志愿填报建议系统

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
</div>

## 技术栈

- **前端框架**: Flutter 3.16+
- **开发语言**: Dart
- **状态管理**: Provider / Riverpod
- **UI设计**: Material Design 3
- **API 服务**: ngrok tunnel (https://marlyn-unalleviative-annabel.ngrok-free.dev)

## 项目结构

> [!NOTE]
>
> 主体代码都在/lib文件夹中

```
flutter_app/
├── analysis_options.yaml          # 代码分析配置
├── assets/
│   └── images/                     # 图片资源
├── lib/
│   ├── main.dart                   # 应用入口
│   └── src/
│       ├── app.dart                # 应用主体
│       ├── services/
│       │   ├── api_client.dart     # API 客户端封装
│       │   └── api_exception.dart  # API 异常处理
│       ├── theme/
│       │   └── app_theme.dart      # 主题配置
│       ├── screens/
│       │   ├── auth/
│       │   │   └── auth_screen.dart        # 认证页面
│       │   └── home/
│       │       ├── home_shell.dart         # 主页框架
│       │       ├── pages/
│       │       │   ├── analysis_page.dart      # 分析页面
│       │       │   ├── college_page.dart       # 院校页面
│       │       │   ├── dashboard_page.dart     # 仪表盘页面
│       │       │   ├── heat_page.dart          # 热度页面
│       │       │   ├── info_page.dart          # 高考页面
│       │       │   ├── profile_page.dart       # 个人资料页面
│       │       │   └── recommend_page.dart     # 推荐页面
│       │       └── widgets/
│       │           └── immersive_header.dart   # 沉浸式头部组件
│       └── widgets/
│           ├── section_card.dart               # 区块卡片组件
│           ├── stat_chip.dart                  # 统计标签组件
│           ├── tag_chip.dart                   # 标签组件
│           └── timeline_item.dart              # 时间线项目组件
└── pubspec.yaml                    # 依赖配置
```

## 已接入的后端接口

### 1. 用户认证接口

#### 注册
- **接口**: `POST /auth/register`
- **状态**: ✅ 已接入
- **使用位置**: `auth_screen.dart`

#### 登录
- **接口**: `POST /auth/login`
- **状态**: ✅ 已接入
- **使用位置**: `auth_screen.dart`


### 2. 院校查询接口

#### 院校列表（分页）
- **接口**: `GET /colleges?page={page}&pageSize={pageSize}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 全国院校标签页

#### 院校筛选
- **接口**: `GET /colleges?province={province}&is985={0|1}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 筛选功能

#### 院校详情
- **接口**: `GET /colleges/{collegeCode}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 院校详情弹窗

#### 院校历年录取数据
- **接口**: `GET /colleges/{collegeCode}/admissions?province={province}&year={year}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 历年录取标签页

### 3. 成绩管理接口

···

### 4. 高中录取记录接口

#### 查询高中录取记录
- **接口**: `GET /school-enrollment?schoolName={schoolName}&graduationYear={year}`
- **状态**: ✅ 已接入 【不完善】
- **使用位置**: `college_page.dart` - 高中录取标签页

## 接口认证说明

### Token 获取
用户登录成功后，后端返回 JWT token，前端需要保存并在后续请求中使用。

### Token 使用
需要认证的接口必须在请求头中添加：
```
Authorization: Bearer {token}
```

### Token 管理
- Token 存储在 `AuthScope` 中
- 通过 `AuthScope.of(context).session.token` 获取
- 在 `api_client.dart` 中自动添加到请求头

## 数据本地存储

### 成绩记录
- **存储方式**: 本地内存存储（临时）
- **位置**: `info_page.dart` - `_localScores`
- **说明**: 当前版本使用本地存储，待后端接口完善后切换到云端存储

### 收藏功能
- **存储方式**: 本地内存存储（临时）
- **位置**: `college_page.dart` - `_favoriteCollegeIds`
- **说明**: 待收藏接口开发后接入后端


## 快速开始

### 环境要求

- Flutter SDK 3.16 或更高版本
- Dart SDK 3.0 或更高版本
- iOS 开发需要 Xcode 12 或更高版本
- Android 开发需要 Android Studio 或 VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/nova728/edu_flutter.git
cd edu_flutter_app
```

2. **安装依赖**
```bash
flutter pub get
```

3. **检查环境**
```bash
flutter doctor
```

4. **运行项目**

Web 端:
```bash
 flutter run -d chrome --web-port=55136
```

iOS 模拟器:
```bash
flutter run -d ios
```

Android 模拟器:
```bash
flutter run -d android
```

使用本地 API (可选):
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## 更新日志

### 11-11

#### 项目更新说明

- 前端登录/注册流程新增省份选择，并接入注册接口校验。
- 个人信息页调用 `/student-score/mine` 展示最新成绩，院校页支持省份筛选与院校详情查看。
- 推荐、院校等页面完成导航互通和卡片样式优化，完善按钮交互。
- 后端开放 `/colleges` 查询能力

### 11-13

#### 项目更新说明

- 完善高考页面（info_page.dart）新增省份选择功能，支持新旧高考
- 更改院校页面（college_page.dart）/ 我的页面（profile_page.dart）布局
- 新增收藏院校页面（favorite_colleges_page.dart），实现院校收藏功能
- 优化推荐页面（recommend_page.dart）交互体验

### 11-16

- API改为穿透
- 完善院校查询、筛选、详情、历年录取等接口
- 添加历年录取分数线查看模块：院校➡️全国院校➡️对应大学详情页➡️历年录取

### 交互问题

- [ ] 院校页面（collegeg_page.dart）有一个收藏功能，对应的数据库表现在是否有收藏字段





