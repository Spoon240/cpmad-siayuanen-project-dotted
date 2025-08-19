import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/firebaseauth_service.dart';
import 'register_page.dart';
import 'splashScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAEAEA), // off white
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("welcome to ", style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w600),),
              const Text("dotted.", style: TextStyle(fontFamily: 'Poppins', fontSize: 45, fontWeight: FontWeight.w700, color: Color(0xFF6B7E7A))),
              const SizedBox(height: 20,),

              _buildNormalField("Email", Icons.email_outlined, emailController),
              const SizedBox(height: 15,),

              _buildPasswordField(
                label: "Password",
                icon: Icons.lock_outline,
                controller: passwordController,
                obscureText: obscurePassword,
                onToggle: () {
                  setState(() => obscurePassword = !obscurePassword);
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      Fluttertoast.showToast(msg: "Please fill in all fields.");
                      return;
                    }

                    final user = await FirebaseAuthService().signIn(email: email, password: password);

                    if (user != null) {
                      Fluttertoast.showToast(msg: "Login successful!");
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SplashPage()),
                        // MaterialPageRoute(builder: (context) => MainScreen()),
                      );
                    } 
                    
                    else {
                      Fluttertoast.showToast(msg: "Login failed.");
                    }
                  },

                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B7E7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                  ),

                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ), // button

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
         ),
      )
    );
  }

  Widget _buildNormalField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20,),
        hintText: label,
        hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12,),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

      ),
    );
  }

  Widget _buildPasswordField({ required String label, required IconData icon, required TextEditingController controller, required bool obscureText, required VoidCallback onToggle,}){
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),

      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20,),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: onToggle,
        ),

        hintText: label,
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),

        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),

      ),
    );
  }
}