import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/pages/project_detail_page.dart';
import 'package:crew_check/pages/team_projects_page.dart';
import 'package:crew_check/widgets/common_widgets.dart';
import 'package:crew_check/widgets/add_project_dialog.dart';

// ── Donut Chart ───────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  _DonutPainter({required this.progress, required this.trackColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, -pi / 2, 2 * pi, false,
        Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false,
        Paint()..color = fillColor..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.trackColor != trackColor || old.fillColor != fillColor;
}

class _DonutChart extends StatelessWidget {
  final double progress;
  final int percent;
  final Color color;
  final double size;
  const _DonutChart({required this.progress, required this.percent, required this.color, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(progress: progress, trackColor: Colors.grey.shade200, fillColor: color),
          ),
          Text('$percent%', style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ── Model tim dengan progress ─────────────────────────────────────────────────
class _TeamEntry {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final int percent; // 0–100
  final DateTime? deadline;
  _TeamEntry({required this.doc, required this.percent, required this.deadline});
}

// ── Dashboard ─────────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _firestore = FirebaseFirestore.instance;

  static const _chartColors = [
    Color(0xFFE57373), Color(0xFF64B5F6), Color(0xFFFFB74D),
    Color(0xFF81C784), Color(0xFFBA68C8),
  ];
  Color _chartColor(int index) => _chartColors[index % _chartColors.length];

  // ── Summary stream ────────────────────────────────────────────────────────
  Stream<Map<String, int>> _getSummaryCountsStream(String uid) {
    final teamsStream = _firestore.collection('teams').where('memberUids', arrayContains: uid).snapshots();
    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? teamsSub;
      final taskSubs = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
      final taskSnaps = <String, QuerySnapshot<Map<String, dynamic>>>{};

      DateTime? parseDate(dynamic raw) {
        if (raw is String) {
          try { final p = raw.split('-'); return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])); } catch (_) {}
        } else if (raw is Timestamp) { final d = raw.toDate(); return DateTime(d.year, d.month, d.day); }
        return null;
      }

      void updateCounts() {
        final today = DateTime.now();
        final todayStr = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        String pad(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        int todayCount = 0, weekCount = 0, completedCount = 0;
        for (final snap in taskSnaps.values) {
          final total = snap.docs.length;
          var done = 0;
          for (final doc in snap.docs) {
            final data = doc.data();
            final completed = data['completed'] as bool? ?? false;
            final date = parseDate(data['date']);
            if (!completed && date != null) {
              final ts = pad(date);
              if (ts == todayStr) todayCount++;
              if (ts.compareTo(pad(weekStart)) >= 0 && ts.compareTo(pad(weekEnd)) <= 0) weekCount++;
            }
            if (completed) done++;
          }
          if (total > 0 && done == total) completedCount++;
        }
        controller.add({'today': todayCount, 'week': weekCount, 'completed': completedCount});
      }

      void subscribeToTeam(String teamId) {
        if (taskSubs.containsKey(teamId)) return;
        taskSubs[teamId] = _firestore.collection('teams').doc(teamId).collection('tasks').snapshots()
            .listen((snap) { taskSnaps[teamId] = snap; updateCounts(); }, onError: controller.addError);
      }

      teamsSub = teamsStream.listen((snap) {
        final ids = snap.docs.map((d) => d.id).toList();
        for (final id in ids) subscribeToTeam(id);
        final removed = taskSubs.keys.where((id) => !ids.contains(id)).toList();
        for (final id in removed) { taskSubs[id]?.cancel(); taskSubs.remove(id); taskSnaps.remove(id); }
        updateCounts();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await teamsSub?.cancel();
        for (final s in taskSubs.values) await s.cancel();
      };
    });
  }

  // ── Stream teams + progress sekaligus ────────────────────────────────────
  Stream<List<_TeamEntry>> _getTeamsWithProgressStream(String uid) {
    final teamsStream = _firestore.collection('teams').where('memberUids', arrayContains: uid).snapshots();
    return Stream.multi((controller) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? teamsSub;
      final taskSubs = <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};
      final taskSnaps = <String, QuerySnapshot<Map<String, dynamic>>>{};
      List<QueryDocumentSnapshot<Map<String, dynamic>>> teamDocs = [];

      void emit() {
        final entries = teamDocs.map((doc) {
          final snap = taskSnaps[doc.id];
          final total = snap?.docs.length ?? 0;
          final done = snap?.docs.where((d) => (d.data()['completed'] as bool?) ?? false).length ?? 0;
          final percent = total == 0 ? 0 : ((done / total) * 100).round();
          final ts = doc.data()['deadline'] as Timestamp?;
          return _TeamEntry(doc: doc, percent: percent, deadline: ts?.toDate());
        }).toList();

        // Sort: belum selesai dulu (by deadline), sudah selesai ke bawah
        entries.sort((a, b) {
          final aDone = a.percent == 100;
          final bDone = b.percent == 100;
          if (aDone != bDone) return aDone ? 1 : -1;
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });

        controller.add(entries);
      }

      teamsSub = teamsStream.listen((snap) {
        teamDocs = snap.docs;
        for (final doc in teamDocs) {
          if (!taskSubs.containsKey(doc.id)) {
            taskSubs[doc.id] = _firestore.collection('teams').doc(doc.id).collection('tasks').snapshots()
                .listen((ts) { taskSnaps[doc.id] = ts; emit(); }, onError: controller.addError);
          }
        }
        final ids = teamDocs.map((d) => d.id).toList();
        final removed = taskSubs.keys.where((id) => !ids.contains(id)).toList();
        for (final id in removed) { taskSubs[id]?.cancel(); taskSubs.remove(id); taskSnaps.remove(id); }
        emit();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await teamsSub?.cancel();
        for (final s in taskSubs.values) await s.cancel();
      };
    });
  }

  String _formatDeadline(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  String _daysLeft(DateTime? deadline) {
    if (deadline == null) return '-';
    final today = DateTime.now();
    final diff = DateTime(deadline.year, deadline.month, deadline.day)
        .difference(DateTime(today.year, today.month, today.day)).inDays;
    if (diff < 0) return 'Lewat';
    if (diff == 0) return 'Hari ini';
    return '$diff Hari Lagi';
  }

  Widget _buildTeamCard(int index, _TeamEntry entry) {
    final data = entry.doc.data();
    final title = data['projectName'] ?? 'Projek';
    final desc = data['description'] ?? '-';
    final deadlineTs = data['deadline'] as Timestamp?;
    final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
    final color = _chartColor(index);
    final daysLeft = _daysLeft(entry.deadline);
    final progress = entry.percent.clamp(0, 100) / 100.0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailPage(teamId: entry.doc.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorKuning,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: bodyTextStyle(size: 20), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(desc, style: bodyTextStyle(size: 13, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 28,
                    child: Row(
                      children: [
                        SizedBox(
                          width: (members.length > 4 ? 4 : members.length) * 18.0 + 14,
                          child: Stack(
                            children: List.generate(members.length > 4 ? 4 : members.length, (i) => Positioned(
                              left: i * 18.0,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: _chartColors[i % _chartColors.length],
                                child: Text((members[i]['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            )),
                          ),
                        ),
                        if (members.length > 4)
                          Text('+${members.length - 4} Anggota', style: bodyTextStyle(size: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(daysLeft, style: bodyTextStyle(size: 12, color: color)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _DonutChart(progress: progress, percent: entry.percent, color: color, size: 64),
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
          ? Center(child: Text('Silakan masuk untuk melihat dashboard', style: bodyTextStyle(size: 18)))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 20),
                  width: double.infinity,
                  color: colorMerah,
                  child: Center(child: Text('CrewCheck', style: crewCheckTitleStyle(size: 40, color: Colors.white))),
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
                            final counts = snapshot.data ?? {'today': 0, 'week': 0, 'completed': 0};
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryCard(counts['today']!.toString(), 'Projek\nHari ini'),
                                _buildSummaryCard(counts['week']!.toString(), 'Projek\nMinggu ini'),
                                _buildSummaryCard(counts['completed']!.toString(), 'Projek\nSelesai'),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        Text('Progress Tugas', style: bodyTextStyle(size: 28)),
                        const SizedBox(height: 12),
                        StreamBuilder<List<_TeamEntry>>(
                          stream: _getTeamsWithProgressStream(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(child: Text('Gagal memuat projek: ${snapshot.error}', style: bodyTextStyle(color: Colors.red)));
                            }

                            final all = snapshot.data ?? [];
                            // Hanya tampilkan yang belum 100%
                            final active = all.where((e) => e.percent < 100).take(3).toList();

                            if (active.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Text('Semua projek sudah selesai! 🎉', style: bodyTextStyle(size: 16, color: Colors.grey)),
                                ),
                              );
                            }

                            return Column(
                              children: [
                                ...active.asMap().entries.map((e) => _buildTeamCard(e.key, e.value)),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamProjectsPage())),
                                    child: Text('lihat semua projek tim >', style: bodyTextStyle(size: 14, color: colorBiru)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: buildAddFab(context),
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
        const SizedBox(height: 4),
        Text(t, style: bodyTextStyle(size: 12), textAlign: TextAlign.center),
      ],
    ),
  );
}