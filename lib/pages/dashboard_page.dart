import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firestore = FirebaseFirestore.instance;

  Future<int> _getProjectCountToday() async {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final snapshot = await _firestore
        .collection('tasks')
        .where('date', isEqualTo: todayString)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getProjectCountThisWeek() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final snapshot = await _firestore
        .collection('tasks')
        .where(
          'date',
          isGreaterThanOrEqualTo:
              '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}',
        )
        .where(
          'date',
          isLessThanOrEqualTo:
              '${weekEnd.year}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}',
        )
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getCompletedProjectCount() async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .get();
    return snapshot.docs.length;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getProjectsStream() {
    return _firestore
        .collection('tasks')
        .orderBy('date', descending: true)
        .limit(3)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      body: Column(
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
                      FutureBuilder<int>(
                        future: _getProjectCountToday(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return _buildSummaryCard(
                            count.toString(),
                            'Proyek Hari ini',
                          );
                        },
                      ),
                      FutureBuilder<int>(
                        future: _getProjectCountThisWeek(),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return _buildSummaryCard(
                            count.toString(),
                            'Proyek Minggu ini',
                          );
                        },
                      ),
                      FutureBuilder<int>(
                        future: _getCompletedProjectCount(),
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
                  Text('Progress Tugas', style: bodyTextStyle(size: 28)),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _getProjectsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Tidak ada tugas',
                            style: bodyTextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      final tasks = snapshot.data!.docs;

                      return Column(
                        children: tasks.map((task) {
                          final data = task.data();
                          final title = data['title'] ?? 'Untitled';
                          final description =
                              data['description'] ?? 'No description';
                          final progress =
                              (data['progress'] as num?)?.toInt() ?? 0;

                          return _buildProjectCard(
                            title,
                            description,
                            progress,
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

  Widget _buildProjectCard(String title, String desc, int prog) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(15),
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
            Text(title, style: bodyTextStyle(size: 22)),
            Text('$prog%'),
          ],
        ),
        Text(desc, style: bodyTextStyle(color: Colors.black54)),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: prog / 100,
          backgroundColor: Colors.white,
          color: colorMerah,
          minHeight: 8,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    ),
  );
}
