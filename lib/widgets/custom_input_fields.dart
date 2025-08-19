import 'package:flutter/material.dart';

  Widget buildNormalField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 12,),
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


//   Widget _buildNormalField(String label, IconData icon, TextEditingController controller) {
//   return TextField(
//     controller: controller,
//     style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
//     decoration: InputDecoration(
//       prefixIcon: Icon(icon, size: 20),
//       hintText: label,
//       hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding: const EdgeInsets.all(18),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(15),
//         borderSide: BorderSide.none,
//       ),
//     ),
//   );
// }