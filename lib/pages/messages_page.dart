import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      bottomNavigationBar: buildBottomNavBar(context),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorMerah,
            padding: const EdgeInsets.only(top: 60, bottom: 20),
            child: Center(
              child: Text(
                'CrewCheck',
                style: crewCheckTitleStyle(size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pesan', style: bodyTextStyle(size: 28)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorBiru,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cari Percakapan..',
                      style: bodyTextStyle(size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Conversations list from `teams` collection
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat percakapan',
                      style: bodyTextStyle(size: 18),
                    ),
                  );
                }

                final teams = snapshot.data?.docs ?? [];
                if (teams.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada percakapan',
                      style: bodyTextStyle(size: 18),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: teams.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final teamDoc = teams[index];
                    final teamId = teamDoc.id;
                    final teamData = teamDoc.data();
                    final name = (teamData['name'] as String?) ?? teamId;
                    final avatarUrl = teamData['avatarUrl'] as String?;

                    // fetch last message for this team
                    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('teams')
                          .doc(teamId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .get(),
                      builder: (context, lastSnap) {
                        String lastText = '';
                        String sender = '';
                        String time = '';
                        if (lastSnap.hasData &&
                            lastSnap.data!.docs.isNotEmpty) {
                          final msg = lastSnap.data!.docs.first.data();
                          lastText = (msg['text'] as String?) ?? '';
                          sender = (msg['senderName'] as String?) ?? '';
                          time = _formatTime(msg['timestamp'] as Timestamp?);
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/chat/room',
                              arguments: {'teamId': teamId, 'groupName': name},
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorKuning,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  backgroundColor: avatarUrl == null
                                      ? Colors.white
                                      : null,
                                  child: avatarUrl == null
                                      ? Text(name.isNotEmpty ? name[0] : '?')
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: bodyTextStyle(size: 20),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        sender.isNotEmpty
                                            ? '$sender: $lastText'
                                            : lastText,
                                        style: bodyTextStyle(
                                          size: 16,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  time,
                                  style: bodyTextStyle(
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colorMerah,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
