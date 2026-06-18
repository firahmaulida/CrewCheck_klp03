import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/widgets/common_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login Gagal: $e')));
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
                        'Masuk',
                        style: bodyTextStyle(size: 45, color: Colors.white),
                      ),
                      Text(
                        'Masuk ke akun Anda',
                        style: bodyTextStyle(size: 20, color: colorKuning),
                      ),
                      const SizedBox(height: 30),
                      buildTextField(
                        hint: 'Email',
                        icon: Icons.email,
                        controller: _emailController,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Lupa Sandi',
                            style: bodyTextStyle(size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                      buildButton('Masuk', colorBiru, _login),
                      const SizedBox(height: 20),
                      Text(
                        'Atau masuk dengan',
                        style: bodyTextStyle(size: 18, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildSocialButton(
                            'Google',
                            Colors.white,
                            Colors.black,
                            Icons.g_mobiledata,
                          ),
                          const SizedBox(width: 20),
                          buildSocialButton(
                            'Facebook',
                            const Color(0xFF3B5998),
                            Colors.white,
                            Icons.facebook,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Belum Punya Akun? Daftar',
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
