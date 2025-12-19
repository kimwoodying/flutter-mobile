import 'package:flutter/material.dart';
import '../widgets/chat_modal.dart';

class ChatHostScreen extends StatelessWidget {
  const ChatHostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('챗봇')),
      body: const ChatModal(),
    );
  }
}