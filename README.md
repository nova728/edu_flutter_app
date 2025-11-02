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
│       │       │   ├── info_page.dart          # 信息页面
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
flutter run -d chrome
```

iOS 模拟器:
```bash
flutter run -d ios
```

Android 模拟器:
```bash
flutter run -d android
```

