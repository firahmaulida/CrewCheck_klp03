import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';
import 'package:crew_check/pages/project_detail_page.dart';

class TeamProjectsPage extends StatelessWidget {
  const TeamProjectsPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _teamsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('teams')
        .where('memberUids', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatDeadline(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorBg,
      bottomNavigationBar: buildBottomNavBar(context),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              color: colorMerah,
              child: Center(
                child: Text(
                  'CrewCheck',
                  style: crewCheckTitleStyle(size: 40, color: Colors.white),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Daftar projek tim', style: bodyTextStyle(size: 22)),
              ],
            ),
          ),
          Expanded(
            child: user == null
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _teamsStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Belum ada projek tim',
                            style: bodyTextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          return _TeamProjectCard(
                            teamId: doc.id,
                            projectName: data['projectName'] ?? 'Tanpa nama',
                            description: data['description'] ?? '',
                            deadlineText: _formatDeadline(
                              data['deadline'] as Timestamp?,
                            ),
                            members: List<Map<String, dynamic>>.from(
                              data['members'] ?? [],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeamProjectCard extends StatelessWidget {
  final String teamId;
  final String projectName;
  final String description;
  final String deadlineText;
  final List<Map<String, dynamic>> members;

  const _TeamProjectCard({
    required this.teamId,
    required this.projectName,
    required this.description,
    required this.deadlineText,
    required this.members,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _tasksStream() {
    return FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('tasks')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailPage(teamId: teamId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorKuning,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(projectName, style: bodyTextStyle(size: 22)),
                  const SizedBox(height: 4),
                  Text(
                    'Tenggat: $deadlineText',
                    style: bodyTextStyle(size: 13, color: Colors.black54),
                  ),
                  Text(
                    description,
                    style: bodyTextStyle(size: 14, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 28,
                    child: Stack(
                      children: List.generate(
                        members.length > 4 ? 4 : members.length,
                        (i) => Positioned(
                          left: i * 18.0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: colorBiru,
                            child: Text(
                              (members[i]['name'] ?? '?')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (members.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${members.length - 4} Anggota',
                        style: bodyTextStyle(size: 12, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _tasksStream(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final total = docs.length;
                final completed = docs
                    .where((d) => (d.data()['completed'] as bool?) ?? false)
                    .length;
                final percent = total == 0 ? 0 : ((completed / total) * 100).round();
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    '$percent%',
                    style: bodyTextStyle(size: 13, color: colorMerah),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}