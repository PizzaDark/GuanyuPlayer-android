import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final String? modelPath;
  final double volume;
  final Function(String?) onModelPathChanged;
  final Function(double) onVolumeChanged;
  
  const SettingsScreen({
    super.key,
    required this.modelPath,
    required this.volume,
    required this.onModelPathChanged,
    required this.onVolumeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String? _modelPath;
  late double _volume;

  @override
  void initState() {
    super.initState();
    _modelPath = widget.modelPath;
    _volume = widget.volume;
  }

  Future<void> _browseModelFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    
    if (result != null) {
      setState(() {
        _modelPath = result;
      });
      widget.onModelPathChanged(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模型路径已更新，语音识别将重新加载')),
      );
    }
  }

  void _clearModelPath() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认'),
        content: const Text('确定要恢复默认模型路径吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _modelPath = null;
              });
              widget.onModelPathChanged(null);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已恢复默认模型路径')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: '音量设置',
            icon: Icons.volume_up,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        label: '${(_volume * 100).toInt()}%',
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                          });
                          widget.onVolumeChanged(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${(_volume * 100).toInt()}%',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '语音识别模型',
            icon: Icons.mic,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.folder, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _modelPath ?? '默认: sherpa-onnx-streaming-zipformer-zh-14M',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _browseModelFolder,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('选择模型文件夹'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _modelPath != null ? _clearModelPath : null,
                          child: const Text('恢复默认'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '可替换为不同语言的 Sherpa-ONNX 模型。有效的模型文件夹应包含：.onnx 模型文件和 tokens.txt。',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '关于',
            icon: Icons.info,
            children: [
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('作者'),
                subtitle: Text('@依然匹萨吧'),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('B站主页'),
                subtitle: const Text('space.bilibili.com/6297797'),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () async {
                  const url = 'https://space.bilibili.com/6297797';
                  try {
                    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('无法打开链接，请手动访问: https://space.bilibili.com/6297797'),
                        ),
                      );
                    }
                  }
                },
              ),
              const ListTile(
                leading: Icon(Icons.article),
                title: Text('说明'),
                subtitle: Text('免费软件，禁止商用贩卖，音乐版权归音乐作者所有'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}
