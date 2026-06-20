import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';
import 'package:crew_check/pages/team_projects_page.dart';

class JoinTeamPage extends StatefulWidget {
  const JoinTeamPage({super.key});

  @override
  State<JoinTeamPage> createState() => _JoinTeamPageState();
}

class _JoinTeamPageState extends State<JoinTeamPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinTeam() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode tim terlebih dahulu')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('teams')
          .where('teamCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode tim tidak ditemukan')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final teamDoc = query.docs.first;
      final memberUids = List<String>.from(teamDoc.data()['memberUids'] ?? []);

      if (memberUids.contains(user.uid)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamu sudah tergabung di tim ini')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Ambil data profil user dari koleksi users (sesuai register_page.dart)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final username = userData?['username'] ?? user.displayName ?? 'Anggota';

      await teamDoc.reference.update({
        'memberUids': FieldValue.arrayUnion([user.uid]),
        'members': FieldValue.arrayUnion([
          {
            'uid': user.uid,
            'name': username,
            'email': user.email ?? '',
            'role': 'Anggota',
            'jobTitle': '',
          },
        ]),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeamProjectsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal gabung tim: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                Text('Gabung ke tim', style: bodyTextStyle(size: 22)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorKrem,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: colorKuning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Anda masuk sebagai',
                            style: bodyTextStyle(size: 14, color: Colors.black54)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: colorKuning,
                              child: Icon(Icons.person, color: colorMerah),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? 'Pengguna',
                                    style: bodyTextStyle(size: 18),
                                  ),
                                  Text(
                                    user?.email ?? '',
                                    style: bodyTextStyle(
                                        size: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorKrem,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: colorKuning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kode Tim', style: bodyTextStyle(size: 18)),
                        const SizedBox(height: 4),
                        Text(
                          'Mintalah kode tim projek kepada ketua tim, lalu masukkan kode di sini',
                          style: bodyTextStyle(size: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        buildTextField(
                          hint: 'Kode Tim',
                          icon: Icons.vpn_key,
                          controller: _codeController,
                        ),
                      ],
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
                        onPressed: _isLoading ? null : _joinTeam,
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
                                'Gabung',
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