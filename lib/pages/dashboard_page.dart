import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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

  Stream<Map<String, int>> _getSummaryCountsStream(String uid) {
    final teamsStream = _firestore
        .collection('teams')
        .where('memberUids', arrayContains: uid)
        .snapshots();

    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? teamsSub;
      final taskSubscriptions =
          <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
      final taskSnapshots = <String, QuerySnapshot<Map<String, dynamic>>>{};

      DateTime? parseTaskDate(dynamic rawDate) {
        if (rawDate is String) {
          try {
            final parts = rawDate.split('-');
            if (parts.length == 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } catch (_) {
            return null;
          }
        } else if (rawDate is Timestamp) {
          final d = rawDate.toDate();
          return DateTime(d.year, d.month, d.day);
        } else if (rawDate is DateTime) {
          return DateTime(rawDate.year, rawDate.month, rawDate.day);
        }
        return null;
      }

      void updateCounts() {
        final today = DateTime.now();
        final todayString =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekStartStr =
            '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
        final weekEndStr =
            '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

        int todayCount = 0;
        int weekCount = 0;
        int completedCount = 0;

        for (final snapshot in taskSnapshots.values) {
          final total = snapshot.docs.length;
          var completedTasks = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final completed = data['completed'] as bool? ?? false;
            final taskDate = parseTaskDate(data['date']);

            if (!completed && taskDate != null) {
              final taskDateString =
                  '${taskDate.year}-${taskDate.month.toString().padLeft(2, '0')}-${taskDate.day.toString().padLeft(2, '0')}';
              if (taskDateString == todayString) {
                todayCount += 1;
              }
              if (taskDateString.compareTo(weekStartStr) >= 0 &&
                  taskDateString.compareTo(weekEndStr) <= 0) {
                weekCount += 1;
              }
            }
            if (completed) {
              completedTasks += 1;
            }
          }

          if (total > 0 && completedTasks == total) {
            completedCount += 1;
          }
        }

        controller.add({
          'today': todayCount,
          'week': weekCount,
          'completed': completedCount,
        });
      }

      void subscribeToTeam(String teamId) {
        if (taskSubscriptions.containsKey(teamId)) {
          return;
        }

        final subscription = _firestore
            .collection('teams')
            .doc(teamId)
            .collection('tasks')
            .snapshots()
            .listen((snapshot) {
              taskSnapshots[teamId] = snapshot;
              updateCounts();
            }, onError: controller.addError);

        taskSubscriptions[teamId] = subscription;
      }

      void cancelUnusedTeams(List<String> teamIds) {
        final removed = taskSubscriptions.keys
            .where((teamId) => !teamIds.contains(teamId))
            .toList();
        for (final teamId in removed) {
          taskSubscriptions[teamId]?.cancel();
          taskSubscriptions.remove(teamId);
          taskSnapshots.remove(teamId);
        }
      }

      teamsSub = teamsStream.listen((teamsSnapshot) {
        final teamIds = teamsSnapshot.docs.map((doc) => doc.id).toList();

        for (final teamId in teamIds) {
          subscribeToTeam(teamId);
        }
        cancelUnusedTeams(teamIds);
        updateCounts();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await teamsSub?.cancel();
        for (final sub in taskSubscriptions.values) {
          await sub.cancel();
        }
      };
    });
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
                        StreamBuilder<Map<String, int>>(
                          stream: _getSummaryCountsStream(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              debugPrint(
                                '[summary] stream error: ${snapshot.error}',
                              );
                              // show zeroes but also an error indicator
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSummaryCard('0', 'Tugas Hari ini'),
                                  _buildSummaryCard('0', 'Tugas Minggu ini'),
                                  _buildSummaryCard('0', 'Tugas Selesai'),
                                ],
                              );
                            }

                            final counts =
                                snapshot.data ??
                                {'today': 0, 'week': 0, 'completed': 0};
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryCard(
                                  counts['today']!.toString(),
                                  'Tugas Hari ini',
                                ),
                                _buildSummaryCard(
                                  counts['week']!.toString(),
                                  'Tugas Minggu ini',
                                ),
                                _buildSummaryCard(
                                  counts['completed']!.toString(),
                                  'Tugas Selesai',
                                ),
                              ],
                            );
                          },
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
