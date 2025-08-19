import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUs_Page extends StatelessWidget {
  const AboutUs_Page({super.key});

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
  }

  void _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'siayuanen@gmail.com',
      query: encodeQueryParameters({
        'subject': 'Feedback for Momentum App',
        'body': 'Hello, I would like to share some feedback regarding Momentum App...'
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } 
    else {
      debugPrint("Could not launch email");
    }
  }

  void _callCompany() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+6512345678');

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } 
    else {
      debugPrint("Could not launch phone call");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'About Us',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(35, 60, 35, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // app name
            const Center(child: Text("dotted.", style: TextStyle(fontFamily: 'Poppins', fontSize: 45, fontWeight: FontWeight.w700, color: Color(0xFF6B7E7A)))),
            const SizedBox(height: 25),
            
            //description
            const Text(
              "Dotted is a flexible, intuitive nutrition app that helps you log meals, track calories and weight, scan barcodes, and stay motivated with progress photos. Whether you're starting out or refining your routine, dots makes healthy habits simple and sustainable.",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
            ),

            const SizedBox(height: 50,),
      
            /// Location Section
            const Text(
              'Location',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10,),
            
            _infoTile(Icons.email, '12 Street, Tech Valley, Singapore 567890', Colors.red, null),

            const SizedBox(height: 30,),
      
            /// Contact us Section 
            const Text(
              'Contact Us',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10,),
            
            //Email
            _infoTile(Icons.email, 'dottedsupport@gmail.com', Colors.indigo, _sendEmail),

            const SizedBox(height: 15,),

            //number
            _infoTile(Icons.phone, '+65 1234 5678', Colors.green, _callCompany),

          ],
        ),
      ),
    );
  }

  Widget _infoTile( IconData icon, String label, Color iconColor, VoidCallback? onTap,) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA), // Slightly darker than #F1F1F1
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 24),
        title: Text(label,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
        onTap: onTap, 
      ),
    );
  }
}


// Container(
//   decoration: BoxDecoration(
//     color: const Color(0xFFEAEAEA), // Slightly darker than #F1F1F1
//     borderRadius: BorderRadius.circular(12),
//   ),

//   child: ListTile(
//     leading: const Icon(Icons.email, color: Colors.indigo, size: 24), // Email Icon
//     title: const Text(
//       "mtmsupport@gmail.com",
//       style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
//     ),
//     onTap: (){

//     }, //call function
//   ),

// ),