import 'package:flutter/material.dart';
import 'widgets/home_drawer.dart';
import '../../chat/presentation/widgets/chat_input_field.dart';
import '../../chat/presentation/widgets/message_bubble.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _messages = [];

  void _handleSend(String text) {
    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _messages.add({'text': 'Sacred Wisdom: \$text involves spiritual depth.', 'isUser': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sacred Wisdom')),
      drawer: const HomeDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageBubble(text: msg['text'], isUser: msg['isUser']);
              },
            ),
          ),
          ChatInputField(onSend: _handleSend),
        ],
      ),
    );
  }
}
