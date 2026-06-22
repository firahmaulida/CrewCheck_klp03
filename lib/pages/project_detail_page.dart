import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';
import 'package:crew_check/widgets/add_task_dialog.dart';

class ProjectDetailPage extends StatelessWidget {
  final String teamId;

  const ProjectDetailPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: colorBg,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .snapshots(),
        builder: (context, teamSnapshot) {
          if (!teamSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final teamData = teamSnapshot.data!.data();
          if (teamData == null) {
            return Center(
              child: Text('Tim tidak ditemukan', style: bodyTextStyle()),
            );
          }

          final members = List<Map<String, dynamic>>.from(
            teamData['members'] ?? [],
          );
          final isKetua = members.any(
            (m) => m['uid'] == user?.uid && m['role'] == 'Ketua',
          );
          final projectName = teamData['projectName'] ?? 'Projek';
          final description = teamData['description'] ?? '';

          return Stack(
            children: [
              Column(
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
                          style: crewCheckTitleStyle(
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            projectName,
                            style: bodyTextStyle(size: 22),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Anggota',
                            style: bodyTextStyle(
                              size: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 56, right: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        description,
                        style: bodyTextStyle(size: 14, color: Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _MemberTaskGroup(
                          teamId: teamId,
                          memberUid: member['uid'] ?? '',
                          memberName: member['name'] ?? 'Tanpa nama',
                          memberRole: member['role'] ?? 'Anggota',
                          jobTitle: member['jobTitle'] ?? '',
                          isCurrentUser: member['uid'] == user?.uid,
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (isKetua)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: colorMerah,
                    onPressed: () => showAddTaskDialog(
                      context,
                      teamId: teamId,
                      members: members,
                      defaultDate: (teamData['deadline'] as Timestamp?)
                          ?.toDate(),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: buildBottomNavBar(context),
    );
  }
}

class _MemberTaskGroup extends StatelessWidget {
  final String teamId;
  final String memberUid;
  final String memberName;
  final String memberRole;
  final String jobTitle;
  final bool isCurrentUser;

  const _MemberTaskGroup({
    required this.teamId,
    required this.memberUid,
    required this.memberName,
    required this.memberRole,
    required this.jobTitle,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final tasksStream = FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('tasks')
        .where('assignedTo', isEqualTo: memberUid)
        .snapshots();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorKuning,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorMerah, width: 2.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colorMerah, width: 2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(memberName, style: bodyTextStyle(size: 20)),
                Text(
                  jobTitle,
                  style: bodyTextStyle(size: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: tasksStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    'Belum ada tugas',
                    style: bodyTextStyle(size: 13, color: Colors.black45),
                  ),
                );
              }
              return Column(
                children: List.generate(docs.length, (i) {
                  final doc = docs[i];
                  final data = doc.data();
                  final title = data['title'] ?? 'Tugas';
                  final completed = data['completed'] as bool? ?? false;
                  final canToggle = isCurrentUser;
                  final isLast = i == docs.length - 1;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Checkbox(
                              value: completed,
                              onChanged: canToggle
                                  ? (value) {
                                      doc.reference.update({
                                        'completed': value,
                                      });
                                    }
                                  : null,
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  title,
                                  style: bodyTextStyle(
                                    size: 16,
                                    color: completed
                                        ? Colors.black54
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Divider(
                            color: colorMerah.withAlpha((0.3 * 255).round()),
                            thickness: 1.5,
                          ),
                        ),
                    ],
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
