import 'package:flutter/material.dart';

class KeywordsScreen extends StatefulWidget {
  final List<String> keywords;
  
  const KeywordsScreen({super.key, required this.keywords});

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  late List<TextEditingController> _controllers;
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _controllers = widget.keywords.map((k) => TextEditingController(text: k)).toList();
    // 确保至少有一个输入框
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
    // 创建焦点节点
    for (int i = 0; i < _controllers.length; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addKeyword() {
    if (_controllers.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能设置10个关键词')),
      );
      return;
    }
    setState(() {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    });
  }

  void _removeKeyword(int index) {
    if (_controllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要保留一个关键词')),
      );
      return;
    }
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      _focusNodes[index].dispose();
      _focusNodes.removeAt(index);
    });
  }

  void _saveKeywords() {
    final keywords = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少需要设置一个关键词')),
      );
      return;
    }

    if (keywords.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能设置10个关键词')),
      );
      return;
    }

    // 检查重复
    if (keywords.length != keywords.toSet().length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('关键词不能重复')),
      );
      return;
    }

    Navigator.pop(context, keywords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑关键词'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveKeywords,
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
                    '每个关键词单独输入，最多10个。语音识别时匹配任意关键词即可触发播放。',
                    style: TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _controllers.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${index + 1}.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            decoration: InputDecoration(
                              hintText: '输入关键词 ${index + 1}',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeKeyword(index),
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
                    onPressed: _controllers.length < 10 ? _addKeyword : null,
                    icon: const Icon(Icons.add),
                    label: Text('添加关键词 (${_controllers.length}/10)'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveKeywords,
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
