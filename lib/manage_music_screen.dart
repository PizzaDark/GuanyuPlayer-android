import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

class ManageMusicScreen extends StatefulWidget {
  final List<String> musicFiles;
  final String currentPreset;
  
  const ManageMusicScreen({
    super.key,
    required this.musicFiles,
    required this.currentPreset,
  });

  @override
  State<ManageMusicScreen> createState() => _ManageMusicScreenState();
}

class _ManageMusicScreenState extends State<ManageMusicScreen> {
  late List<String> _musicFiles;
  late String _currentPreset;
  final AudioPlayer _previewPlayer = AudioPlayer();
  int? _previewingIndex;

  @override
  void initState() {
    super.initState();
    _musicFiles = List.from(widget.musicFiles);
    _currentPreset = widget.currentPreset;
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _addMusicFiles() async {
    if (_musicFiles.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能添加10个音乐文件')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      for (final file in result.files) {
        if (_musicFiles.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已达到10个文件上限')),
          );
          break;
        }

        if (file.path != null && !_musicFiles.contains(file.path!)) {
          setState(() {
            _musicFiles.add(file.path!);
            _currentPreset = 'custom';
          });
        }
      }
    }
  }

  void _removeMusicFile(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要从列表中删除\n"${_musicFiles[index].split('/').last}"\u5417\uff1f\n\n\uff08\u6587\u4ef6\u4e0d\u4f1a\u4ece\u78c1\u76d8\u5220\u9664\uff09'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (_previewingIndex == index) {
                  _stopPreview();
                }
                _musicFiles.removeAt(index);
                _currentPreset = 'custom';
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _previewMusic(int index) async {
    if (_previewingIndex == index) {
      _stopPreview();
      return;
    }

    try {
      final file = _musicFiles[index];
      if (file.startsWith('/')) {
        await _previewPlayer.setFilePath(file);
      } else {
        await _previewPlayer.setAsset('assets/audio/$file');
      }
      await _previewPlayer.play();
      setState(() {
        _previewingIndex = index;
      });

      _previewPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _previewingIndex = null;
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('试听失败: $e')),
      );
    }
  }

  void _stopPreview() {
    _previewPlayer.stop();
    setState(() {
      _previewingIndex = null;
    });
  }

  void _applyPreset(String preset) {
    setState(() {
      _currentPreset = preset;
      if (preset == 'classic') {
        _musicFiles = ['guanyu_song.mp3'];
      } else if (preset == 'gacha') {
        _musicFiles = [
          'guanyu_song_1.mp3',
          'guanyu_song_2.mp3',
          'guanyu_song_3.mp3',
          'guanyu_song_4.mp3',
        ];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已应用${preset == 'classic' ? '经典' : '抽卡'}模式')),
    );
  }

  void _save() {
    if (_musicFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要一个音乐文件')),
      );
      return;
    }

    Navigator.pop(context, {
      'files': _musicFiles,
      'preset': _currentPreset,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理音乐'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: '保存',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '最多添加10个音乐文件（支持mp3/wav/ogg等格式）。触发时将随机播放一首。',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyPreset('classic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPreset == 'classic'
                          ? Colors.orange
                          : null,
                    ),
                    child: const Text('经典模式'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyPreset('gacha'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPreset == 'gacha'
                          ? Colors.orange
                          : null,
                    ),
                    child: const Text('抽卡模式'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _musicFiles.isEmpty
                ? const Center(
                    child: Text(
                      '暂无音乐文件\n点击下方按钮添加',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _musicFiles.length,
                    itemBuilder: (context, index) {
                      final file = _musicFiles[index];
                      final fileName = file.split('/').last;
                      final isPreviewing = _previewingIndex == index;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: file.startsWith('/')
                              ? Text(
                                  file,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                )
                              : const Text('内置音频'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPreviewing ? Icons.stop : Icons.play_arrow,
                                  color: isPreviewing ? Colors.red : Colors.blue,
                                ),
                                onPressed: () => _previewMusic(index),
                                tooltip: isPreviewing ? '停止试听' : '试听',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeMusicFile(index),
                                tooltip: '删除',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _musicFiles.length < 10 ? _addMusicFiles : null,
                    icon: const Icon(Icons.add),
                    label: Text('添加文件 (${_musicFiles.length}/10)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 48),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
