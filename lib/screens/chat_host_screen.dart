import 'package:flutter/material.dart';

import '../widgets/chat_modal.dart';

class ChatHostScreen extends StatelessWidget {
  const ChatHostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ChatModal(),
        ),
      ),
    );
  }
}
