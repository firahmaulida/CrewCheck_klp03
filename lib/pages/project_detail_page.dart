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
                          style: crewCheckTitleStyle(size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            projectName,
                            style: bodyTextStyle(size: 22),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          isKetua ? 'Ketua' : 'Anggota',
                          style: bodyTextStyle(
                            size: 13,
                            color: colorMerah,
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
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorKrem,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorKuning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$memberName ($memberRole)',
                  style: bodyTextStyle(size: 16),
                ),
                if (jobTitle.isNotEmpty)
                  Text(
                    jobTitle,
                    style: bodyTextStyle(size: 12, color: Colors.black54),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    'Belum ada tugas',
                    style: bodyTextStyle(size: 13, color: Colors.black45),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final title = data['title'] ?? 'Tugas';
                  final completed = data['completed'] as bool? ?? false;
                  // Hanya anggota yang ditugaskan yang boleh toggle checklist-nya sendiri.
                  final canToggle = isCurrentUser;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CheckboxListTile(
                      value: completed,
                      onChanged: canToggle
                          ? (value) {
                              doc.reference.update({'completed': value});
                            }
                          : null,
                      activeColor: colorMerah,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(title, style: bodyTextStyle(size: 15)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}