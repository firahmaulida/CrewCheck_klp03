import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';
import 'package:crew_check/pages/team_projects_page.dart';
import 'package:crew_check/utils/team_code.dart';

class CreateTeamPage extends StatefulWidget {
  const CreateTeamPage({super.key});

  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _deadlineController = TextEditingController();

  DateTime? _selectedDeadline;
  bool _isLoading = false;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: colorMerah),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _createTeam() async {
    final projectName = _projectNameController.text.trim();
    final description = _descriptionController.text.trim();
    final teamName = _teamNameController.text.trim();

    if (projectName.isEmpty || teamName.isEmpty || _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field terlebih dahulu')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final username = userData?['username'] ?? user.displayName ?? 'Ketua';

      final teamCode = generateTeamCode();

      await FirebaseFirestore.instance.collection('teams').add({
        'projectName': projectName,
        'description': description,
        'teamName': teamName,
        'teamCode': teamCode,
        'deadline': Timestamp.fromDate(_selectedDeadline!),
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'memberUids': [user.uid],
        'members': [
          {
            'uid': user.uid,
            'name': username,
            'email': user.email ?? '',
            'role': 'Ketua',
            'jobTitle': '',
          },
        ],
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeamProjectsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat tim: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
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
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Buat tim', style: bodyTextStyle(size: 22)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Projek', style: bodyTextStyle(size: 16)),
                  const SizedBox(height: 6),
                  buildTextField(
                    hint: 'Nama Projek',
                    icon: Icons.description_outlined,
                    controller: _projectNameController,
                  ),
                  const SizedBox(height: 16),
                  Text('Deskripsi', style: bodyTextStyle(size: 16)),
                  const SizedBox(height: 6),
                  buildTextField(
                    hint: 'Deskripsi',
                    icon: Icons.notes,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 16),
                  Text('Nama Tim', style: bodyTextStyle(size: 16)),
                  const SizedBox(height: 6),
                  buildTextField(
                    hint: 'Nama tim',
                    icon: Icons.groups_outlined,
                    controller: _teamNameController,
                  ),
                  const SizedBox(height: 16),
                  Text('Tenggat', style: bodyTextStyle(size: 16)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDeadline,
                    child: AbsorbPointer(
                      child: buildTextField(
                        hint: 'HH/BB/TTTT',
                        icon: Icons.calendar_today,
                        controller: _deadlineController,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text('Batal', style: bodyTextStyle(size: 16)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createTeam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorBiru,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Buat',
                                style: bodyTextStyle(
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}