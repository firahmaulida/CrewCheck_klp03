import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class ChatPage extends StatefulWidget {
  final String teamId;
  final String groupName;

  const ChatPage({
    super.key,
    required this.teamId,
    this.groupName = 'Grup PBM',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _messageController.text.trim().isEmpty) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('messages')
        .add({
          'text': messageText,
          'senderId': currentUser.uid,
          'senderName': currentUser.displayName ?? currentUser.email ?? 'User',
          'timestamp': FieldValue.serverTimestamp(),
        });

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorBg,
      // Tidak ada bottomNavigationBar dan FAB
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorMerah,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Tombol kembali di kiri
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/chat'),
                  ),
                ),
                // Judul di tengah
                Column(
                  children: [
                    Text(
                      'CrewCheck',
                      style: crewCheckTitleStyle(size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.groupName,
                      style: bodyTextStyle(size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(widget.teamId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat pesan',
                      style: bodyTextStyle(size: 18),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = data['text'] as String? ?? '';
                    final senderName = data['senderName'] as String? ?? 'User';
                    final senderId = data['senderId'] as String? ?? '';
                    final isOwnMessage = senderId == currentUser?.uid;

                    return Align(
                      alignment: isOwnMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isOwnMessage ? colorKuning : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft:
                                Radius.circular(isOwnMessage ? 20 : 0),
                            bottomRight:
                                Radius.circular(isOwnMessage ? 0 : 20),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: bodyTextStyle(
                                size: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(text, style: bodyTextStyle(size: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: bodyTextStyle(size: 16),
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle:
                          bodyTextStyle(size: 16, color: Colors.black38),
                      filled: true,
                      fillColor: colorKrem,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: colorMerah,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}