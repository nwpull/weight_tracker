# 体重追踪 App (Weight Tracker)

一款功能完整的 Flutter 跨平台体重管理应用，支持 iOS 和 Android。

## 功能特性

### 核心功能
- **体重记录** - 手动输入体重、日期选择、备注
- **体重趋势图表** - 可视化体重变化趋势，支持多周期查看
- **历史记录管理** - 搜索、筛选、删除记录

### 智能功能
- **OCR 识别** - 拍照识别体重秤上的数字，自动填充体重
- **照片管理** - 上传和管理身体对比照片
- **时间线展示** - 按时间线浏览照片

### 视频功能
- **对比视频生成** - 选择照片生成带转场效果的对比视频
- **文字叠加** - 支持日期和体重标签

### 目标管理
- **目标设置** - 设置目标体重和目标日期
- **进度追踪** - 环形进度图展示达成进度

## 技术栈

| 类别 | 技术 |
|---|---|
| 框架 | Flutter 3.5+ |
| 状态管理 | Riverpod |
| 本地数据库 | Drift (SQLite) |
| 图表 | fl_chart |
| OCR | Google ML Kit |
| 视频生成 | FFmpeg Kit |
| 路由 | GoRouter |

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # MaterialApp 配置
├── core/                        # 共享核心代码
│   ├── constants/               # 常量定义
│   ├── theme/                   # 主题配置
│   ├── widgets/                 # 通用组件
│   └── router/                  # 路由配置
├── data/                        # 数据层
│   ├── database/                # 数据库定义
│   └── repositories/            # 数据仓库
└── features/                    # 功能模块
    ├── weight_entry/            # 体重录入
    ├── weight_history/          # 历史记录
    ├── weight_chart/            # 趋势图表
    ├── photo_management/        # 照片管理
    ├── video_generation/        # 视频生成
    ├── goals/                   # 目标管理
    └── settings/                # 设置
```

## 快速开始

### 环境要求
- Flutter SDK >= 3.5.0
- Dart SDK >= 3.5.0
- Android Studio / Xcode

### 安装依赖

```bash
flutter pub get
```

### 代码生成

```bash
# 生成 Drift 数据库代码
flutter pub run build_runner build

# 生成 Riverpod 代码
flutter pub run build_runner build --delete-conflicting-outputs
```

### 运行应用

```bash
flutter run
```

## 主要依赖

```yaml
dependencies:
  flutter_riverpod: ^2.6.1      # 状态管理
  drift: ^2.22.1                # 数据库 ORM
  fl_chart: ^0.69.2             # 图表
  google_mlkit_text_recognition: ^0.15.1  # OCR
  ffmpeg_kit_flutter_new_gpl: ^1.6.5      # 视频生成
  go_router: ^14.6.2            # 路由
  image_picker: ^1.1.2          # 照片选择
```

## 开发说明

### 数据库迁移

修改数据库表结构后，需要：
1. 更新 `schemaVersion`
2. 添加迁移逻辑
3. 重新运行代码生成

### OCR 识别

OCR 功能使用 Google ML Kit，支持离线识别。识别精度受以下因素影响：
- 光照条件
- 体重秤显示清晰度
- 拍摄角度

### 视频生成

视频生成使用 FFmpeg，注意：
- 处理时间较长，建议异步执行
- 会增加 APK 体积约 30-50MB
- 长时间处理可能导致设备发热

## License

MIT License
