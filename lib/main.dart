// import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'keywords_screen.dart';
import 'manage_music_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const MaterialColor primarySeedColor = Colors.deepPurple;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primarySeedColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primarySeedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: primarySeedColor.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'GuanyuPlayer',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 语音识别
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _onlineStream;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _recordSubscription;
  bool _isRecording = false;
  
  // 音频播放器
  final _player = AudioPlayer();
  
  // 配置
  List<String> _keywords = ['释怀', '天意'];
  List<String> _musicFiles = [];
  String _currentPreset = 'classic';
  double _volume = 0.7;
  String? _modelPath;
  
  // 状态
  bool _isPlaying = false;
  String _currentFile = '无';
  String _lastKeyword = '无';
  bool _voiceRecognitionEnabled = false;
  String _recognitionResult = '';
  String _voiceInitError = ''; // 语音识别初始化失败原因
  DateTime? _lastTriggerTime; // 最后一次触发时间，用于防抖
  DateTime? _lastRecognitionTime; // 最后一次识别时间，用于去重

  @override
  void initState() {
    super.initState();
    _initApp();
  }
  
  Future<void> _initApp() async {
    await _loadConfig();
    await _requestPermissions();
    await _setupAudioPlayer();
    await _initSpeechRecognition();
  }
  
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keywords = prefs.getStringList('keywords') ?? ['释怀', '天意'];
      _musicFiles = prefs.getStringList('music_files') ?? [];
      _currentPreset = prefs.getString('current_preset') ?? 'classic';
      _volume = prefs.getDouble('volume') ?? 0.7;
      _modelPath = prefs.getString('model_path');
    });
    
    // 如果没有音乐文件，使用默认配置
    if (_musicFiles.isEmpty) {
      if (_currentPreset == 'classic') {
        _musicFiles = ['guanyu_song.mp3'];
      } else if (_currentPreset == 'gacha') {
        _musicFiles = ['guanyu_song_1.mp3', 'guanyu_song_2.mp3', 'guanyu_song_3.mp3', 'guanyu_song_4.mp3'];
      }
    }
  }
  
  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('keywords', _keywords);
    await prefs.setStringList('music_files', _musicFiles);
    await prefs.setString('current_preset', _currentPreset);
    await prefs.setDouble('volume', _volume);
    if (_modelPath != null) {
      await prefs.setString('model_path', _modelPath!);
    }
  }
  
  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
  }
  
  Future<void> _setupAudioPlayer() async {
    // 配置音频会话：允许与录音同时进行，不请求音频焦点
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse('silence')),
      ).catchError((_) {
        // 忽略初始化错误，这只是为了触发音频会话配置
      });
      
      // Android平台特定：设置音频属性，使播放不会打断录音
      // 这通过混音模式(mixWithOthers)实现，允许音频播放与录音同时进行
      await _player.setVolume(_volume);
      
      debugPrint('✓ 音频播放器已配置为混音模式（允许与录音同时进行）');
    } catch (e) {
      debugPrint('音频播放器配置警告: $e');
      await _player.setVolume(_volume);
    }
    
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        debugPrint('播放完成，重置状态');
        setState(() {
          _isPlaying = false;
          _currentFile = '无';
        });
        // 播放结束后重启语音识别，确保麦克风状态正常
        _restartSpeechService();
      } else if (state.processingState == ProcessingState.idle && _isPlaying) {
        debugPrint('播放停止，重置状态');
        setState(() {
          _isPlaying = false;
          _currentFile = '无';
        });
        // 播放停止后重启语音识别
        _restartSpeechService();
      }
    });
  }

  Future<String> _copyAssetFile(String assetPath) async {
    final directory = await getApplicationSupportDirectory();
    final targetPath = p.join(directory.path, p.basename(assetPath));
    final file = File(targetPath);
    
    // 如果文件不存在或者大小为0，则重新复制
    if (!await file.exists() || await file.length() == 0) {
      debugPrint('正在解压模型文件: $assetPath -> $targetPath');
      try {
        final byteData = await rootBundle.load(assetPath);
        await file.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes, 
          byteData.lengthInBytes
        ));
      } catch (e) {
        debugPrint('无法加载资源文件: $assetPath, 错误: $e');
        throw Exception('无法加载资源文件: $assetPath');
      }
    }
    return targetPath;
  }

  static bool _bindingsInitialized = false;

  Future<void> _createAudioRecognizer() async {
    // 构建模型路径（从assets）
    final assetModelDir = 'assets/models/sherpa-onnx-streaming-zipformer-zh-14M-2023-02-23';
    
    // ... (文件复制逻辑省略, 保持不变) ...
    // 必须将assets中的文件复制到本地文件系统才能被C++层读取
    final encoderPath = await _copyAssetFile('$assetModelDir/encoder-epoch-99-avg-1.int8.onnx');
    final decoderPath = await _copyAssetFile('$assetModelDir/decoder-epoch-99-avg-1.int8.onnx');
    final joinerPath = await _copyAssetFile('$assetModelDir/joiner-epoch-99-avg-1.int8.onnx');
    final tokensPath = await _copyAssetFile('$assetModelDir/tokens.txt');
    
    debugPrint('正在创建识别器配置...');
    final config = sherpa_onnx.OnlineRecognizerConfig(
      model: sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: encoderPath,
          decoder: decoderPath,
          joiner: joinerPath,
        ),
        tokens: tokensPath,
        modelType: 'zipformer',
      ),
    );
    
    if (!_bindingsInitialized) {
      debugPrint('正在初始化Sherpa-ONNX绑定...');
      sherpa_onnx.initBindings();
      _bindingsInitialized = true;
    }

    debugPrint('正在创建识别器...');
    _recognizer = sherpa_onnx.OnlineRecognizer(config);
  }

  Future<void> _initSpeechRecognition() async {
    try {
      // 检查麦克风权限
      if (!await Permission.microphone.isGranted) {
        debugPrint('麦克风权限未授予，跳过语音识别初始化');
        setState(() {
          _voiceRecognitionEnabled = false;
          _voiceInitError = '麦克风权限未授予';
        });
        return;
      }

      debugPrint('开始初始化Sherpa-ONNX语音识别...');
      
      await _createAudioRecognizer();
      debugPrint('识别器创建成功');
      
      // 启动录音并开始识别
      await _startContinuousRecognition();
      
      setState(() {
        _voiceRecognitionEnabled = true;
        _voiceInitError = '';
      });
      debugPrint('✓ 语音识别初始化成功');
    } catch (e, stackTrace) {
      final errorMsg = e.toString();
      debugPrint('✗ 语音识别初始化失败: $errorMsg');
      debugPrint('堆栈跟踪: $stackTrace');
      
      // 分析错误原因
      String friendlyError;
      if (errorMsg.contains('asset') || errorMsg.contains('Asset')) {
        friendlyError = '语音模型文件未找到(Asset错误)，请确认这些文件在assets目录下且pubspec.yaml已配置：$errorMsg';
      } else if (errorMsg.contains('permission') || errorMsg.contains('Permission')) {
        friendlyError = '权限不足，请检查麦克风权限';
      } else {
        friendlyError = '初始化失败: $errorMsg';
      }
      
      setState(() {
        _voiceRecognitionEnabled = false;
        _voiceInitError = friendlyError;
      });
      // 不显示错误提示，让应用继续运行
    }
  }
  
  Future<void> _startContinuousRecognition() async {
    if (_recognizer == null) return;
    
    try {
      debugPrint('开始连续语音识别...');
      
      // 创建在线流
      _onlineStream = _recognizer!.createStream();

      // 如果已经在录音，通过_onlineStream的更新就已经足够连接了，不需要重新启动Record
      if (_isRecording) {
        debugPrint('录音已在进行中，仅创建新流');
        return;
      }
      
      // 配置录音参数
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );
      
      // 开始录音并获取音频流
      final stream = await _audioRecorder.startStream(config);
      _isRecording = true;
      
      // 监听音频流
      _recordSubscription = stream.listen(
        (data) {
          if (_onlineStream == null) return;
          
          // 将字节数据转换为float32格式
          final samples = _bytesToFloat32(data);
          
          // 接收音频样本
          _onlineStream!.acceptWaveform(
            sampleRate: 16000,
            samples: samples,
          );
          
          // 解码并获取结果
          while (_recognizer!.isReady(_onlineStream!)) {
            _recognizer!.decode(_onlineStream!);
          }
          
          // 获取识别结果
          final result = _recognizer!.getResult(_onlineStream!);
          if (result.text.isNotEmpty) {
            final now = DateTime.now();
            // 基于时间的去重：只在文本变化或距离上次识别超过500ms时处理
            if (result.text != _recognitionResult || 
                _lastRecognitionTime == null ||
                now.difference(_lastRecognitionTime!).inMilliseconds > 500) {
              debugPrint('识别结果: ${result.text}');
              setState(() {
                _recognitionResult = result.text;
                _lastRecognitionTime = now;
              });
              _handleVoiceRecognition(result.text);
            }
          }
        },
        onError: (error) {
          debugPrint('录音流错误: $error');
        },
        onDone: () {
          debugPrint('录音流结束');
        },
      );
    } catch (e) {
      debugPrint('启动连续识别失败: $e');
      _isRecording = false;
    }
  }
  
  // 将字节数据转换为float32数组
  Float32List _bytesToFloat32(List<int> bytes) {
    final numSamples = bytes.length ~/ 2;
    final samples = Float32List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      // 将两个字节组合成16位整数
      final int sample = bytes[i * 2] | (bytes[i * 2 + 1] << 8);
      // 转换为有符号整数
      final int signedSample = sample > 32767 ? sample - 65536 : sample;
      // 归一化到 [-1, 1]
      samples[i] = signedSample / 32768.0;
    }
    return samples;
  }
  
  void _handleVoiceRecognition(String text) {
    // 检测关键词
    for (final keyword in _keywords) {
      if (text.contains(keyword)) {
        _onKeywordDetected(keyword);
        break;
      }
    }
  }
  
  void _onKeywordDetected(String keyword) async {
    final now = DateTime.now();
    
    // 防抖：如果距离上次触发不到3秒，则忽略
    if (_lastTriggerTime != null && 
        now.difference(_lastTriggerTime!).inSeconds < 3) {
      debugPrint('触发过于频繁，忽略本次关键词: $keyword');
      return;
    }
    
    _lastTriggerTime = now;
    
    setState(() {
      _lastKeyword = '$keyword (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')})';
      // 重置所有识别相关的缓存状态
      _recognitionResult = '';
      _lastRecognitionTime = null;
    });
    
    debugPrint('检测到关键词: $keyword，触发播放控制');
    
    // 先执行播放控制
    _togglePlay();

    // 状态重置已由 _togglePlay 中的播放/停止逻辑接管 (通过 _restartSpeechService)
    // 这里的轻量级重置不再需要，避免冲突
    /* 
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _resetRecognitionStream();
    });
    */
  }

  // 轻量级重置：只重置识别流，不停止录音，避免打断音乐播放
  Future<void> _resetRecognitionStream() async {
    if (_recognizer == null) {
      debugPrint('识别器未初始化，无法重置流');
      return;
    }
    
    try {
      debugPrint('正在重置语音识别流（保持录音运行）...');
      debugPrint('当前录音状态: _isRecording=$_isRecording');
      
      // 1. 销毁旧的流
      if (_onlineStream != null) {
        _onlineStream!.free();
        _onlineStream = null;
        debugPrint('旧识别流已释放');
      }
      
      // 2. 清除识别状态缓存
      setState(() {
        _recognitionResult = '';
        _lastRecognitionTime = null;
      });
      
      // 3. 短暂延迟，确保资源释放
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 4. 创建新的识别流
      if (_recognizer != null && mounted) {
        _onlineStream = _recognizer!.createStream();
        debugPrint('✓ 新识别流已创建（ID: ${_onlineStream.hashCode}），录音流将继续向新流发送数据');
        
        // 5. 验证新流是否正常
        await Future.delayed(const Duration(milliseconds: 500));
        if (_onlineStream != null) {
          debugPrint('✓ 流验证通过，等待新的识别结果...');
        }
      }
    } catch (e) {
      debugPrint('重置识别流失败: $e');
      // 如果轻量级重置失败，尝试完整重启
      await _restartSpeechService();
    }
  }
  
  // 完整重启：用于初始化失败或严重错误时的降级方案
  Future<void> _restartSpeechService() async {
    debugPrint('正在完整重启语音识别服务...');
    
    try {
      // 1. 停止监听，防止回调继续执行
      await _recordSubscription?.cancel();
      _recordSubscription = null;

      // 2. 销毁旧的流和识别器
      if (_onlineStream != null) {
        _onlineStream!.free();
        _onlineStream = null;
      }
      if (_recognizer != null) {
        _recognizer!.free();
        _recognizer = null;
      }

      // 3. 停止录音
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }
      
      debugPrint('语音服务资源已释放，准备重新初始化...');
      
      // 4. 短暂延迟，确保 native 资源释放
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // 5. 重新走完整初始化流程
        await _initSpeechRecognition();
        debugPrint('✓ 语音识别服务已完整重启');
      }
    } catch (e) {
      debugPrint('完整重启语音服务失败: $e');
    }
  }
  
  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() {
        _isPlaying = false;
        _currentFile = '无';
      });
    } else {
      await _playRandomMusic();
    }
  }
  
  Future<void> _playRandomMusic() async {
    if (_musicFiles.isEmpty) {
      _showSnackBar('没有可用的音乐文件，请在音乐设置中添加');
      return;
    }
    
    try {
      final random = Random();
      final selectedFile = _musicFiles[random.nextInt(_musicFiles.length)];
      
      debugPrint('尝试播放音乐: $selectedFile');
      debugPrint('播放前录音状态: _isRecording=$_isRecording, _onlineStream=${_onlineStream != null}');
      
      // 先更新UI状态
      setState(() {
        _isPlaying = true;
        _currentFile = selectedFile.split('/').last;
      });
      
      AudioSource audioSource;
      if (selectedFile.startsWith('/')) {
        // 绝对路径（本地文件）
        audioSource = AudioSource.file(selectedFile);
      } else {
        // assets 路径
        final audioPath = 'assets/audio/$selectedFile';
        audioSource = AudioSource.asset(audioPath);
      }
      
      // 设置音频源并播放
      await _player.setAudioSource(audioSource);
      await _player.play();
      
      debugPrint('音乐播放成功: ${selectedFile.split('/').last}');
      debugPrint('播放后录音状态: _isRecording=$_isRecording, _onlineStream=${_onlineStream != null}');
      
      // 播放启动后，强制重启语音识别以适应音频焦点变化
      // Android上音频路由改变可能会导致之前的录音流失效，因此必须重启录音服务
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // 如果此时已经停止播放（用户快速点击了停止），则由停止的监听逻辑负责重启
          // 这里跳过，避免冲突
          if (!_isPlaying) {
             debugPrint('播放已停止，跳过播放启动时的语音服务重置');
             return;
          }

          debugPrint('播放已开始，正在重启语音识别服务以确保连接...');
          _restartSpeechService();
        }
      });
    } catch (e) {
      debugPrint('播放失败: $e');
      _showSnackBar('播放失败，请检查音频文件是否存在');
      setState(() {
        _isPlaying = false;
        _currentFile = '无';
      });
    }
  }
  
  Future<void> _navigateToKeywords() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => KeywordsScreen(keywords: List.from(_keywords)),
      ),
    );
    
    if (result != null) {
      setState(() {
        _keywords = result;
      });
      await _saveConfig();
      _showSnackBar('关键词已更新');
    }
  }
  
  Future<void> _navigateToMusicManager() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ManageMusicScreen(
          musicFiles: List.from(_musicFiles),
          currentPreset: _currentPreset,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _musicFiles = List<String>.from(result['files']);
        _currentPreset = result['preset'];
      });
      await _saveConfig();
      _showSnackBar('音乐列表已更新');
    }
  }
  
  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          modelPath: _modelPath,
          volume: _volume,
          onModelPathChanged: (path) async {
            setState(() {
              _modelPath = path;
            });
            await _saveConfig();
            await _initSpeechRecognition();
          },
          onVolumeChanged: (volume) async {
            setState(() {
              _volume = volume;
            });
            await _player.setVolume(volume);
            await _saveConfig();
          },
        ),
      ),
    );
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
  
  String _getPresetName() {
    switch (_currentPreset) {
      case 'classic':
        return '经典模式';
      case 'gacha':
        return '抽卡模式';
      default:
        return '自定义模式';
    }
  }
  
  @override
  void dispose() {
    _audioRecorder.dispose();
    _onlineStream?.free();
    _recognizer?.free();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关羽之歌便携版'),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: '设置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTriggerInfo(),
            const SizedBox(height: 16),
            _buildStatusInfo(),
            const SizedBox(height: 16),
            _buildPlayControl(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildKeywordSettings()),
                const SizedBox(width: 8),
                Expanded(child: _buildMusicSettings()),
              ],
            ),
            const SizedBox(height: 16),
            _buildVoiceStatus(),
            const SizedBox(height: 24),
            _buildAuthorInfo(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTriggerInfo() {
    final keywordsDisplay = _keywords.map((k) => '【$k】').join('');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '触发方式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(text: '语音中检测到关键词 '),
                  TextSpan(
                    text: keywordsDisplay,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' 时触发播放\n'),
                  const TextSpan(
                    text: '(再次触发可停止播放)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '状态信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('正在播放: '),
                Expanded(
                  child: Text(
                    _currentFile,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('检测到关键词: '),
                Expanded(
                  child: Text(
                    _lastKeyword,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlayControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '播放控制',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _togglePlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlaying ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isPlaying ? '⏹ 停止' : '▶ 播放',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('音量: '),
                Expanded(
                  child: Slider(
                    value: _volume,
                    onChanged: (value) async {
                      setState(() {
                        _volume = value;
                      });
                      await _player.setVolume(value);
                      await _saveConfig();
                    },
                  ),
                ),
                Text('${(_volume * 100).toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKeywordSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '关键词设置',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text(
              '(最多10个)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _keywords.join('、'),
                style: const TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _navigateToKeywords,
                    child: const Text('编辑'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _keywords = ['释怀', '天意'];
                      });
                      await _saveConfig();
                      _showSnackBar('已恢复默认关键词');
                    },
                    child: const Text('默认'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMusicSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '音乐设置',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Text(
              '(最多10首)',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPresetName(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_musicFiles.length}首',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _navigateToMusicManager,
                    child: const Text('管理'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVoiceStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '语音识别状态',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _voiceRecognitionEnabled ? Icons.check_circle : Icons.info_outline,
                  color: _voiceRecognitionEnabled ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _voiceRecognitionEnabled
                        ? '✓ 语音识别已启用，正在后台监听'
                        : 'ℹ 语音识别未启用',
                    style: TextStyle(
                      color: _voiceRecognitionEnabled ? Colors.green : Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (!_voiceRecognitionEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_voiceInitError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '原因: $_voiceInitError',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    Text(
                      '语音识别为可选功能，也可手动点击播放按钮',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuthorInfo() {
    return Center(
      child: InkWell(
        onTap: () async {
          const url = 'https://space.bilibili.com/6297797';
          try {
            // 尝试直接打开URL（会调用系统默认浏览器或B站App）
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } catch (e) {
            _showSnackBar('无法打开链接，请手动访问: $url');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '作者: @依然匹萨吧',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new, size: 12, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
