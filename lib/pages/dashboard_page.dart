import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/pages/project_detail_page.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firestore = FirebaseFirestore.instance;

  Stream<int> _getProjectCountTodayStream(String uid) {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _firestore
        .collectionGroup('tasks')
        .where('assignedTo', isEqualTo: uid)
        .where('date', isEqualTo: todayString)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getProjectCountThisWeekStream(String uid) {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekStartStr =
        '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final weekEndStr =
        '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

    return _firestore
        .collectionGroup('tasks')
        .where('assignedTo', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: weekStartStr)
        .where('date', isLessThanOrEqualTo: weekEndStr)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> _getCompletedProjectCountStream(String uid) {
    return _firestore
        .collectionGroup('tasks')
        .where('assignedTo', isEqualTo: uid)
        .where('completed', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getTeamProjectsStream(
    String uid,
  ) {
    return _firestore
        .collection('teams')
        .where('memberUids', arrayContains: uid)
        .snapshots();
  }

  String _formatDeadline(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(2, '0')}';
  }

  Widget _buildTeamCard(
    String teamId,
    String title,
    String desc,
    String deadline,
    List<Map<String, dynamic>> members,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProjectDetailPage(teamId: teamId)),
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
                  Text(title, style: bodyTextStyle(size: 22)),
                  const SizedBox(height: 4),
                  Text(
                    'Tenggat: $deadline',
                    style: bodyTextStyle(size: 13, color: Colors.black54),
                  ),
                  Text(
                    desc,
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
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(teamId)
                  .collection('tasks')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final total = docs.length;
                final completed = docs
                    .where((d) => (d.data()['completed'] as bool?) ?? false)
                    .length;
                final percent = total == 0
                    ? 0
                    : ((completed / total) * 100).round();
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorBg,
      body: user == null
          ? Center(
              child: Text(
                'Silakan masuk untuk melihat dashboard',
                style: bodyTextStyle(size: 18),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 20),
                  width: double.infinity,
                  color: colorMerah,
                  child: Center(
                    child: Text(
                      'CrewCheck',
                      style: crewCheckTitleStyle(size: 40, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ringkasan', style: bodyTextStyle(size: 28)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder<int>(
                              stream: _getProjectCountTodayStream(user.uid),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return _buildSummaryCard(
                                  count.toString(),
                                  'Proyek Hari ini',
                                );
                              },
                            ),
                            StreamBuilder<int>(
                              stream: _getProjectCountThisWeekStream(user.uid),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return _buildSummaryCard(
                                  count.toString(),
                                  'Proyek Minggu ini',
                                );
                              },
                            ),
                            StreamBuilder<int>(
                              stream: _getCompletedProjectCountStream(user.uid),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return _buildSummaryCard(
                                  count.toString(),
                                  'Proyek Selesai',
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text('Projek Tim Anda', style: bodyTextStyle(size: 28)),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _getTeamProjectsStream(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Gagal memuat projek tim: ${snapshot.error}',
                                  style: bodyTextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              );
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

                            return Column(
                              children: docs.map((teamDoc) {
                                final data = teamDoc.data();
                                final title = data['projectName'] ?? 'Projek';
                                final description = data['description'] ?? '-';
                                final deadline = _formatDeadline(
                                  data['deadline'] as Timestamp?,
                                );
                                final members = List<Map<String, dynamic>>.from(
                                  data['members'] ?? [],
                                );
                                return _buildTeamCard(
                                  teamDoc.id,
                                  title,
                                  description,
                                  deadline,
                                  members,
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: colorMerah,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: buildBottomNavBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildSummaryCard(String n, String t) => Container(
    width: 100,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: colorKrem,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: colorKuning),
    ),
    child: Column(
      children: [
        Text(n, style: bodyTextStyle(size: 35, color: colorBiru)),
        Text(t, style: bodyTextStyle(size: 12), textAlign: TextAlign.center),
      ],
    ),
  );
}
