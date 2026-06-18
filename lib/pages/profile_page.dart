import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _showEditProfileDialog() async {
    final currentUser = _auth.currentUser;
    final nameController = TextEditingController(
      text: currentUser?.displayName ?? '',
    );
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorBg,
          title: Text('Edit Profil', style: bodyTextStyle(size: 24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: bodyTextStyle(),
                  decoration: InputDecoration(
                    hintText: 'Nama',
                    prefixIcon: const Icon(Icons.person, color: colorMerah),
                    filled: true,
                    fillColor: colorKuning,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  style: bodyTextStyle(),
                  decoration: InputDecoration(
                    hintText: 'Nomor Telepon',
                    prefixIcon: const Icon(Icons.phone, color: colorMerah),
                    filled: true,
                    fillColor: colorKuning,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                phoneController.dispose();
                Navigator.pop(context);
              },
              child: Text(
                'Batal',
                style: bodyTextStyle(size: 16, color: colorMerah),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (currentUser != null) {
                    await currentUser.updateDisplayName(nameController.text);
                    await _firestore
                        .collection('users')
                        .doc(currentUser.uid)
                        .update({
                          'username': nameController.text,
                          'phone': phoneController.text,
                          'email': currentUser.email,
                        });
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  nameController.dispose();
                  phoneController.dispose();
                  Navigator.pop(context);
                  setState(() {});
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Simpan',
                style: bodyTextStyle(size: 16, color: colorMerah),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final oldPasswordController = TextEditingController();
            final newPasswordController = TextEditingController();
            final confirmPasswordController = TextEditingController();
            bool showOldPassword = false;
            bool showNewPassword = false;
            bool showConfirmPassword = false;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: colorBg,
                  title: Text('Ganti Password', style: bodyTextStyle(size: 24)),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: oldPasswordController,
                          obscureText: !showOldPassword,
                          style: bodyTextStyle(),
                          decoration: InputDecoration(
                            hintText: 'Password Lama',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: colorMerah,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showOldPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: colorMerah,
                              ),
                              onPressed: () => setDialogState(
                                () => showOldPassword = !showOldPassword,
                              ),
                            ),
                            filled: true,
                            fillColor: colorKuning,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: newPasswordController,
                          obscureText: !showNewPassword,
                          style: bodyTextStyle(),
                          decoration: InputDecoration(
                            hintText: 'Password Baru',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: colorMerah,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showNewPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: colorMerah,
                              ),
                              onPressed: () => setDialogState(
                                () => showNewPassword = !showNewPassword,
                              ),
                            ),
                            filled: true,
                            fillColor: colorKuning,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: !showConfirmPassword,
                          style: bodyTextStyle(),
                          decoration: InputDecoration(
                            hintText: 'Konfirmasi Password',
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: colorMerah,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: colorMerah,
                              ),
                              onPressed: () => setDialogState(
                                () =>
                                    showConfirmPassword = !showConfirmPassword,
                              ),
                            ),
                            filled: true,
                            fillColor: colorKuning,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        oldPasswordController.dispose();
                        newPasswordController.dispose();
                        confirmPasswordController.dispose();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Batal',
                        style: bodyTextStyle(size: 16, color: colorMerah),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password tidak cocok'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        if (newPasswordController.text.isEmpty ||
                            oldPasswordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Semua field harus diisi'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        try {
                          final currentUser = _auth.currentUser;
                          if (currentUser != null &&
                              currentUser.email != null) {
                            final credential = EmailAuthProvider.credential(
                              email: currentUser.email!,
                              password: oldPasswordController.text,
                            );
                            await currentUser.reauthenticateWithCredential(
                              credential,
                            );
                            await currentUser.updatePassword(
                              newPasswordController.text,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password berhasil diubah'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            oldPasswordController.dispose();
                            newPasswordController.dispose();
                            confirmPasswordController.dispose();
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Ubah',
                        style: bodyTextStyle(size: 16, color: colorMerah),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showLogoutConfirmDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorBg,
          title: Text('Keluar Akun', style: bodyTextStyle(size: 24)),
          content: Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
            style: bodyTextStyle(size: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: bodyTextStyle(size: 16, color: colorMerah),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: Text(
                'Keluar',
                style: bodyTextStyle(size: 16, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final displayName = currentUser?.displayName ?? 'Nama Pengguna';
    final email = currentUser?.email ?? 'email@domain.com';

    return Scaffold(
      backgroundColor: colorBg,
      bottomNavigationBar: buildBottomNavBar(context),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: colorMerah,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            child: Column(
              children: [
                Text(
                  'CrewCheck',
                  style: crewCheckTitleStyle(size: 32, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profil',
                  style: bodyTextStyle(size: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: colorKuning,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'C',
                      style: bodyTextStyle(size: 40, color: colorMerah),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: GoogleFonts.boogaloo(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.boogaloo(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showEditProfileDialog,
                      child: _buildMenuCard(
                        'Edit Profil',
                        Icons.edit,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showChangePasswordDialog,
                      child: _buildMenuCard(
                        'Ganti Password',
                        Icons.lock,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      'Pengaturan Notifikasi',
                      Icons.notifications,
                      trailing: Switch(
                        value: _notificationsEnabled,
                        activeThumbColor: colorMerah,
                        onChanged: (value) =>
                            setState(() => _notificationsEnabled = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      'Hubungi Kami',
                      Icons.phone,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _showLogoutConfirmDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Keluar',
                            style: bodyTextStyle(size: 18, color: Colors.white),
                          ),
                        ),
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

  Widget _buildMenuCard(String title, IconData icon, {Widget? trailing}) {
    final children = <Widget>[
      Icon(icon, color: Colors.black),
      const SizedBox(width: 14),
      Expanded(child: Text(title, style: bodyTextStyle(size: 18))),
    ];
    if (trailing != null) {
      children.add(trailing);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colorKuning,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: children),
    );
  }
}
