import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'main_screen.dart';
import 'setUp_page.dart';

import 'package:provider/provider.dart';                 //  ADD
import '../controllers/diary_provider.dart';             // ADD

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    await Future.delayed(const Duration(seconds: 2)); // delay

    final uid = FirebaseAuth.instance.currentUser?.uid;
    // if (uid == null) return;

    // If somehow there is no user, go to login and clear back stack
    if (uid == null) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      return;
    }//

    //  Start provider streams for the CURRENT user
    await context.read<DiaryProvider>().load();//

    final hasGoals = await FirestoreService().userHasCalorieGoals(uid);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => hasGoals ? const MainScreen() : const SetUpPage(fromSplash: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAEAEA), // Slightly darker than #F1F1F1
      
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text("welcome to ", style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w600),),
              Text("dotted...", style: TextStyle(fontFamily: 'Poppins', fontSize: 70, fontWeight: FontWeight.w700, color: Color(0xFF6B7E7A))),

            ],
          ),
        ),
      ),
    );
  }
}