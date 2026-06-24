import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';
import 'package:crew_check/widgets/add_project_dialog.dart';
import 'package:crew_check/pages/project_detail_page.dart';

// ── Donut ─────────────────────────────────────────────────────────────────────
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
          CustomPaint(size: Size(size, size),
              painter: _DonutPainter(progress: progress, trackColor: Colors.grey.shade200, fillColor: color)),
          Text('$percent%', style: TextStyle(fontSize: size * 0.22, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _TeamEntry {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final int percent;
  final DateTime? deadline;
  _TeamEntry({required this.doc, required this.percent, required this.deadline});
}

// ── Warna ─────────────────────────────────────────────────────────────────────
const _bannerColors = [
  Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFF80DEEA),
  Color(0xFFA5D6A7), Color(0xFFCE93D8), Color(0xFFFFAB91),
];
const _chartColors = [
  Color(0xFFE57373), Color(0xFFFFB74D), Color(0xFF4DD0E1),
  Color(0xFF81C784), Color(0xFFBA68C8), Color(0xFFFF8A65),
];

// ── Page ──────────────────────────────────────────────────────────────────────
class TeamProjectsPage extends StatelessWidget {
  const TeamProjectsPage({super.key});

  Stream<List<_TeamEntry>> _teamsWithProgressStream(String uid) {
    final db = FirebaseFirestore.instance;
    final teamsStream = db.collection('teams').where('memberUids', arrayContains: uid).snapshots();

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

        // Sort: belum selesai dulu (by deadline), 100% ke bawah
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
            taskSubs[doc.id] = db.collection('teams').doc(doc.id).collection('tasks').snapshots()
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
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorBg,
      bottomNavigationBar: buildBottomNavBar(context),
      floatingActionButton: buildAddFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              color: colorMerah,
              child: Center(child: Text('CrewCheck', style: crewCheckTitleStyle(size: 40, color: Colors.white))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Daftar projek tim', style: bodyTextStyle(size: 22)),
              ],
            ),
          ),
          Expanded(
            child: user == null
                ? const SizedBox.shrink()
                : StreamBuilder<List<_TeamEntry>>(
                    stream: _teamsWithProgressStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Gagal memuat projek: ${snapshot.error}',
                            style: bodyTextStyle(color: Colors.red), textAlign: TextAlign.center));
                      }
                      final entries = snapshot.data ?? [];
                      if (entries.isEmpty) {
                        return Center(child: Text('Belum ada projek tim', style: bodyTextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final isDone = entry.percent == 100;
                          final bannerColor = isDone
                              ? Colors.grey.shade300
                              : _bannerColors[index % _bannerColors.length];
                          final chartColor = isDone
                              ? Colors.grey.shade400
                              : _chartColors[index % _chartColors.length];
                          final data = entry.doc.data();
                          final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
                          final visibleMembers = members.length > 4 ? 4 : members.length;

                          return Opacity(
                            opacity: isDone ? 0.45 : 1.0,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ProjectDetailPage(teamId: entry.doc.id))),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: colorKuning,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Banner atas
                                    Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: bannerColor,
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(data['projectName'] ?? 'Projek',
                                                style: bodyTextStyle(size: 20, color: Colors.black87),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                          if (isDone)
                                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        ],
                                      ),
                                    ),
                                    // Body
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Tenggat: ${_formatDeadline(data['deadline'] as Timestamp?)}',
                                                    style: bodyTextStyle(size: 14, color: Colors.black87)),
                                                const SizedBox(height: 2),
                                                Text(
                                                  (data['description'] as String?)?.isNotEmpty == true
                                                      ? '23:59 - ${data['description']}'
                                                      : '-',
                                                  style: bodyTextStyle(size: 13, color: Colors.black54),
                                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: visibleMembers * 18.0 + 14,
                                                      height: 28,
                                                      child: Stack(
                                                        children: List.generate(visibleMembers, (i) => Positioned(
                                                          left: i * 18.0,
                                                          child: CircleAvatar(
                                                            radius: 14,
                                                            backgroundColor: isDone
                                                                ? Colors.grey.shade400
                                                                : _chartColors[i % _chartColors.length],
                                                            child: Text(
                                                              (members[i]['name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        )),
                                                      ),
                                                    ),
                                                    if (members.length > 4)
                                                      Text('+${members.length - 4} Anggota',
                                                          style: bodyTextStyle(size: 12, color: Colors.black54)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: Text('Lihat selengkapnya',
                                                      style: bodyTextStyle(size: 13, color: Colors.black54)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _DonutChart(
                                            progress: entry.percent.clamp(0, 100) / 100.0,
                                            percent: entry.percent,
                                            color: chartColor,
                                            size: 64,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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