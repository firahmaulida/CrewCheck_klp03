import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'username': _userController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
          });
      if (!mounted) return;
      Navigator.pushNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Daftar Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      body: Column(
        children: [
          const SizedBox(height: 60),
          Text('CrewCheck', style: crewCheckTitleStyle()),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: colorMerah,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(100),
                  topRight: Radius.circular(100),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      Text(
                        'Daftar',
                        style: bodyTextStyle(size: 45, color: Colors.white),
                      ),
                      Text(
                        'Buat akun baru',
                        style: bodyTextStyle(size: 20, color: colorKuning),
                      ),
                      const SizedBox(height: 30),
                      buildTextField(
                        hint: 'Username',
                        icon: Icons.person,
                        controller: _userController,
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        hint: 'Email',
                        icon: Icons.email,
                        controller: _emailController,
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        hint: 'Telepon',
                        icon: Icons.smartphone,
                        controller: _phoneController,
                      ),
                      const SizedBox(height: 15),
                      buildTextField(
                        hint: 'Kata Sandi',
                        icon: Icons.lock,
                        isPassword: true,
                        isObscure: _isObscure,
                        controller: _passwordController,
                        onToggle: () =>
                            setState(() => _isObscure = !_isObscure),
                      ),
                      const SizedBox(height: 40),
                      buildButton('Daftar', colorBiru, _register),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sudah Punya Akun? Masuk',
                          style: bodyTextStyle(size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
