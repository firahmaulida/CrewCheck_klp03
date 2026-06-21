import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime selectedDate = DateTime.now();

  // weekOffset 0 = minggu ini, 1 = minggu depan, -1 = minggu lalu, dst.
  int weekOffset = 0;

  /// Senin sebagai awal minggu untuk weekOffset saat ini.
  DateTime get _weekStart {
    final now = DateTime.now();
    final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(
      mondayThisWeek.year,
      mondayThisWeek.month,
      mondayThisWeek.day,
    ).add(Duration(days: weekOffset * 7));
  }

  List<DateTime> get dateOptions =>
      List.generate(7, (index) => _weekStart.add(Duration(days: index)));

  String get _weekLabel {
    switch (weekOffset) {
      case 0:
        return 'Minggu Ini';
      case 1:
        return 'Minggu Depan';
      case -1:
        return 'Minggu Lalu';
      default:
        return weekOffset > 0
            ? '$weekOffset Minggu Lagi'
            : '${weekOffset.abs()} Minggu Lalu';
    }
  }

  void _goToPreviousWeek() {
    setState(() {
      weekOffset -= 1;
      selectedDate = _weekStart;
    });
  }

  void _goToNextWeek() {
    setState(() {
      weekOffset += 1;
      selectedDate = _weekStart;
    });
  }

  String formatDate(DateTime date) {
    final dayNames = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jum\'at',
      'Sabtu',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${dayNames[date.weekday % 7]}';
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getScheduleTasksStream(DateTime date, String uid) {
    final selectedString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final teamsStream = FirebaseFirestore.instance
        .collection('teams')
        .where('memberUids', arrayContains: uid)
        .snapshots();

    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? teamsSub;
      final taskSubscriptions =
          <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
      final taskSnapshots = <String, QuerySnapshot<Map<String, dynamic>>>{};

      void updateTasks() {
        final docs = taskSnapshots.values
            .expand((snapshot) => snapshot.docs)
            .where((doc) => doc.data()['date'] == selectedString)
            .toList();
        controller.add(docs);
      }

      void subscribeToTeam(String teamId) {
        if (taskSubscriptions.containsKey(teamId)) {
          return;
        }

        final subscription = FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .collection('tasks')
            .snapshots()
            .listen((snapshot) {
              taskSnapshots[teamId] = snapshot;
              updateTasks();
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
        updateTasks();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await teamsSub?.cancel();
        for (final sub in taskSubscriptions.values) {
          await sub.cancel();
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      bottomNavigationBar: buildBottomNavBar(context),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: colorKuning,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _goToPreviousWeek,
                        child: Row(
                          children: [
                            const Icon(Icons.chevron_left, color: Colors.black),
                            Text(
                              'Sebelumnya',
                              style: bodyTextStyle(
                                size: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _weekLabel,
                        style: bodyTextStyle(size: 16, color: Colors.black87),
                      ),
                      GestureDetector(
                        onTap: _goToNextWeek,
                        child: Row(
                          children: [
                            Text(
                              'Berikutnya',
                              style: bodyTextStyle(
                                size: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dateOptions.map((date) {
                        final isSelected =
                            date.day == selectedDate.day &&
                            date.month == selectedDate.month &&
                            date.year == selectedDate.year;
                        return GestureDetector(
                          onTap: () => setState(() => selectedDate = date),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : colorKuning,
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? Border.all(color: colorBiru, width: 2)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  date.day.toString().padLeft(2, '0'),
                                  style: crewCheckTitleStyle(
                                    size: 28,
                                    color: colorMerah,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDate(date).split(' ')[1],
                                  style: bodyTextStyle(
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isSelected)
                                  Row(
                                    children: const [
                                      Text(
                                        '•  ',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      Text('•', style: TextStyle(fontSize: 18)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorKrem,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorKuning, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Jadwal ${formatDate(selectedDate)}',
                        style: bodyTextStyle(size: 28, color: Colors.black),
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            return Center(
                              child: Text(
                                'Silakan masuk untuk melihat jadwal',
                                style: bodyTextStyle(size: 18),
                              ),
                            );
                          }

                          return StreamBuilder<
                            List<QueryDocumentSnapshot<Map<String, dynamic>>>
                          >(
                            stream: _getScheduleTasksStream(
                              selectedDate,
                              user.uid,
                            ),
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
                                    'Terjadi kesalahan saat memuat tugas',
                                    style: bodyTextStyle(size: 18),
                                  ),
                                );
                              }
                              final docs = snapshot.data ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Tidak ada tugas untuk tanggal ini',
                                    style: bodyTextStyle(size: 18),
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: docs.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(color: colorMerah, height: 1),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final title =
                                      data['title'] as String? ??
                                      'Tugas tanpa judul';
                                  final completed =
                                      data['completed'] as bool? ?? false;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: colorMerah,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Checkbox(
                                              value: completed,
                                              onChanged: (value) {
                                                docs[index].reference.update({
                                                  'completed': value ?? false,
                                                });
                                              },
                                              activeColor: colorMerah,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: bodyTextStyle(
                                              size: 18,
                                              color: completed
                                                  ? Colors.black54
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
