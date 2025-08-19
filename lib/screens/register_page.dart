import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/firebaseauth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;

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

              _buildNormalField("Username", Icons.person_outline, usernameController),
              const SizedBox(height: 15,),

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
              const SizedBox(height: 15,),

              _buildPasswordField(
                label: "Confirm Password",
                icon: Icons.lock_outline,
                controller: confirmPasswordController,
                obscureText: obscureConfirm,
                onToggle: () {
                  setState(() => obscureConfirm = !obscureConfirm);
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final username = usernameController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();
                    final confirmPassword = confirmPasswordController.text.trim();

                    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
                      Fluttertoast.showToast(msg: "Please fill in all fields.");
                      return;
                    }

                    if (password != confirmPassword) {
                      Fluttertoast.showToast(msg: "Passwords do not match.");
                      return;
                    }

                    final newUser = await FirebaseAuthService().signUp(
                      email: email,
                      password: password,
                      username: username,
                    );

                    if (newUser != null) {
                      Fluttertoast.showToast(msg: "Registration successful!");
                      Navigator.pushReplacementNamed(context, '/login');
                    } 
                    else {
                      Fluttertoast.showToast(msg: "Registration failed.");
                    }
                  }, // button logic

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6B7E7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),

                  child: const Text(
                    "Register",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Login",
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
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12,),
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