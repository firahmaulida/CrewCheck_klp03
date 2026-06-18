import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crew_check/app_theme.dart';
import 'package:crew_check/pages/login_page.dart';
import 'package:crew_check/pages/register_page.dart';
import 'package:crew_check/pages/dashboard_page.dart';
import 'package:crew_check/pages/schedule_page.dart';
import 'package:crew_check/pages/chat_page.dart';
import 'package:crew_check/pages/profile_page.dart';
import 'package:crew_check/pages/messages_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBshv4sP-3jmwTWWyRWScnfDCf9eK1VO34",
      authDomain: "crewcheck-bc369.firebaseapp.com",
      projectId: "crewcheck-bc369",
      storageBucket: "crewcheck-bc369.firebasestorage.app",
      messagingSenderId: "229354290878",
      appId: "1:229354290878:web:55e6bc160cc63ee58968ef",
      measurementId: "G-YQ5RMRQNY0",
    ),
  );

  runApp(const CrewCheckApp());
}

class CrewCheckApp extends StatelessWidget {
  const CrewCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CrewCheck',
      theme: ThemeData(scaffoldBackgroundColor: colorBg, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/schedule': (context) => const SchedulePage(),
        '/chat': (context) => const MessagesPage(),
        '/chat/room': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          return ChatPage(
            teamId: args?['teamId'] ?? 'team_pbm',
            groupName: args?['groupName'] ?? 'Grup PBM',
          );
        },
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
