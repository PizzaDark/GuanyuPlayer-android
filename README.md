# 关羽之歌便携版 (GuanyuPlayer) 安卓版

## 作者：[@依然匹萨吧](https://space.bilibili.com/6297797) 

**桌面版(Windows)：**[PizzaDark/GuanyuPlayer (github.com)](https://github.com/PizzaDark/GuanyuPlayer)

## 功能介绍

  - **[介绍视频](https://www.bilibili.com/video/BV1oFzEBkEtU)**
  - 语音中检测到关键词自动播放（支持多关键词，需要语音模型）
  - 支持音量调节
  - 支持多音乐文件随机播放（预设模式/自定义模式）
  - 可自定义语音识别模型路径
  - **多关键词支持**：从单一关键词扩展到最多10个关键词，任意匹配即可触发
  - **音乐预设模式**：经典模式（单曲循环）、抽卡模式（4首变奏随机爽听）
  - **自定义音乐管理**：支持添加最多10个自定义音频文件，随机播放
  - **自定义模型路径**：模型已内置到程序中，也可自由选择语音识别模型位置，不再限制固定目录
  - **音乐试听功能**：在音乐管理器中可预览试听音频文件
  - **后台运行**：支持后台检测并播放音乐

## 文件说明

  guanyu_song.mp3            - 经典模式音频文件（必需）
  guanyu_song_1~4.mp3        - 抽卡模式音频文件
  sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23/  - 内置语音模型

## 模型下载

### Sherpa-ONNX 语音识别模型

1. 访问 Hugging Face 模型仓库：
   ```
   https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23
   ```

2. 点击 "Files and versions" 标签

3. 下载以下文件（必需）：
   - `encoder-epoch-99-avg-1.int8.onnx`
   - `decoder-epoch-99-avg-1.int8.onnx`
   - `joiner-epoch-99-avg-1.int8.onnx`
   - `tokens.txt`

4. 下载完成后，将整个模型文件夹放置到项目的以下位置：
   ```
   GuanyuPlayer-android/assets/models/sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23/
   ```

5. 确保目录结构如下：
   ```
   assets/
   └── models/
       └── sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23/
           ├── encoder-epoch-99-avg-1.int8.onnx
           ├── decoder-epoch-99-avg-1.int8.onnx
           ├── joiner-epoch-99-avg-1.int8.onnx
           └── tokens.txt
   ```

## 构建方法

### 环境要求

- **Flutter SDK**: ^3.9.0
- **Dart SDK**: ^3.9.0
- **Android Studio** 或 **VS Code**（带 Flutter 插件）
- **Android SDK**: API 21 (Android 5.0) 及以上
- **JDK**: 11 或更高版本

### 快速开始

1. **克隆项目**
   ```bash
   git clone https://github.com/PizzaDark/GuanyuPlayer-android.git
   cd GuanyuPlayer-android
   ```

2. **安装 Flutter 依赖**
   ```bash
   flutter pub get
   ```

3. **下载语音识别模型**（参考上方"模型下载"部分）
   将模型文件放置到 `assets/models/` 目录

4. **添加音频文件**
   - 将 `guanyu_song.mp3` 放置到 `assets/audio/` 目录
   - （可选）将 `guanyu_song_1.mp3` 到 `guanyu_song_4.mp3` 放置到同一目录

5. **连接设备或启动模拟器**
   ```bash
   flutter devices
   ```

6. **运行应用**
   ```bash
   flutter run
   ```

### 构建 APK

**构建调试版本：**
```bash
flutter build apk --debug
```

**构建发布版本：**
```bash
flutter build apk --release
```

**构建 App Bundle（Google Play）：**
```bash
flutter build appbundle --release
```

生成的文件位于：
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 构建分平台 APK

如需为不同 CPU 架构构建独立 APK：
```bash
flutter build apk --split-per-abi
```

## 依赖版本

### 核心依赖

| 依赖包 | 版本 | 用途 |
|--------|------|------|
| flutter | ^3.35.2 | Flutter 框架 |
| sherpa_onnx | ^1.10.31 | 语音识别核心引擎 |
| just_audio | ^0.9.39 | 音频播放 |
| just_audio_background | ^0.0.1-beta.11 | 后台音频播放 |
| record | ^6.0.0 | 麦克风录音 |
| permission_handler | ^11.3.1 | 权限管理 |
| file_picker | ^8.0.5 | 文件选择 |
| shared_preferences | ^2.5.4 | 数据持久化 |
| path_provider | ^2.1.5 | 文件路径管理 |
| provider | ^6.1.2 | 状态管理 |
| google_fonts | ^4.0.4 | 字体库 |
| audio_session | ^0.1.25 | 音频会话管理 |

### 开发依赖

| 依赖包 | 版本 | 用途 |
|--------|------|------|
| flutter_test | sdk | 单元测试 |
| flutter_lints | ^5.0.0 | 代码规范检查 |

完整依赖列表请查看 [pubspec.yaml](pubspec.yaml)

## 语音识别

运行程序后，麦克风检测到任意关键词即可自动触发播放，支持后台运行。

## 关键词设置

  默认关键词：释怀、天意（最多10个）
  修改方法：点击"编辑关键词"按钮，每行输入一个关键词
  恢复默认：点击"恢复默认"按钮
  说明：语音识别时会检测任何一个关键词，匹配到则自动触发播放

## 音乐设置

  **预设模式：**
  - 预设1：经典模式 - 音乐列表使用内置的 guanyu_song.mp3
  - 预设2：抽卡模式 - 音乐列表使用内置的 guanyu_song_1.mp3 ~ guanyu_song_4.mp3

  **自定义模式：**
  - 点击"管理音乐"按钮
  - 最多添加10个音乐文件（支持mp3/wav/ogg格式）
  - 选中文件后点击"试听"可预览
  - 触发播放时将随机播放列表中的一首

  **说明：**
  - 添加的文件不需要复制到程序目录
  - 删除仅从列表移除，不会删除磁盘文件
  - 可随时切换回预设模式

## 常见问题

  Q: 语音识别不工作？
  A: 1. 检查语音模型是否正确放置
     2. 检查麦克风权限是否已授予
     3. 确认语音识别选项已启用

  Q: 如何切换音乐播放模式？
  A: 在音乐管理器中可以选择预设模式或自定义模式

  Q: 后台运行时会自动播放吗？
  A: 是的，后台也可检测关键词并自动播放音乐

## 系统要求

  - Android 5.0 (API 21) 及以上
  - 内存 2GB 以上
  - 麦克风权限（语音识别需要）
  - 存储权限（自定义音乐需要）

## 开源许可证

本项目采用 **[知识共享 署名 - 非商业性使用 - 相同方式共享 4.0 国际许可证 (CC BY-NC-SA 4.0)](LICENSE)** 授权。

### 核心条款说明

1. **允许的行为**：你可以自由复制、修改、分发本项目的代码 / 程序，前提是满足以下条件；
2. **禁止的行为**：严禁将本项目（包括修改后的衍生版本）用于任何商业目的（如出售、付费分发、商业运营等）；
3. 必须遵守：
   - 署名：必须保留原作者信息（[PizzaDark](https://space.bilibili.com/6297797)）；
   - 相同方式共享：若你修改 / 衍生本项目，必须采用与本协议相同的许可证发布。

### 协议完整文本

请查看官方协议全文：https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.zh

### 第三方组件许可证

本软件使用了以下开源组件：

  - Flutter: BSD-3-Clause
  - sherpa_onnx: Apache-2.0
  - just_audio: MIT
  - permission_handler: MIT
  - file_picker: MIT
  - record: MIT
  - shared_preferences: BSD-3-Clause
  - provider: MIT

## 声明

  - 音乐版权归原作者(赵季平)所有，不包含在本许可证范围内
  - 语音模型 sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23 遵循 Apache-2.0 许可证

## 支持作者

如果觉得好用，欢迎到B站关注支持：https://space.bilibili.com/6297797
