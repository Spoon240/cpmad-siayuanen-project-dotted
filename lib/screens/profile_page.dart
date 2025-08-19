import 'package:flutter/material.dart';
import '../services/firebaseauth_service.dart';

import '../services/firestore_service.dart';
import '../model/user.dart';

import 'aboutUs_page.dart';
import 'profile_edit_page.dart';

import 'package:provider/provider.dart';
import '../controllers/diary_provider.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  UserModel? currentUser;
  
  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAEAEA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.black),
                title: const Text("About Us", style: TextStyle(fontFamily: 'Poppins', color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUs_Page()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout", style: TextStyle(fontFamily: 'Poppins', color: Colors.red, fontWeight: FontWeight.bold)),

                onTap: () async {
                  // clear memory
                  context.read<DiaryProvider>().clear();
                  await FirebaseAuthService().signOut();
                  Navigator.pop(context);
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  
                },

              ),
            ],
          ),
        );
      },
    );
  }



  @override
  void initState() {
    super.initState();
    loadUserData();
  } // reloading the function
  

  Future<void> loadUserData() async {
    currentUser = await FirestoreService().fetchCurrentUserProfile();
    setState(() {}); // refresh UI
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),


        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, size: 20, color: Colors.black),
              onPressed: _showOptionsSheet,
            ),
          ),
        ],
      ),

      body: FutureBuilder<UserModel?>(
        future: FirestoreService().fetchCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError){
            return const Center(child: Text("User not found"),);
          }
          if(!snapshot.hasData || snapshot.data == null){
            return const Center(child: Text("User not found"));
          }
          final user = snapshot.data!;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
              child: Column(
                children: [
                  // profile details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PROFILE PIC
                      Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundImage: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                          ? const AssetImage('images/profile-icon-placeholder.png') as ImageProvider
                          : NetworkImage(user.profilePictureUrl!),
                        ),
                      ),
                  
                      // USERNAME, BIO, EDIT BUTTON
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.username ?? "No Name",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            
                            Text(
                              currentUser?.bio ?? "No bio yet.",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 10,),
                  
                            ElevatedButton(
                              onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EditProfilePage(username: user.username, bio: user.bio,)),
                                    
                                  );
                                  await loadUserData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B7E7A),
                                minimumSize: const Size(2, 30), // Width, Height
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Edit",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                                                        
                          ],
                        )
                      ),
                  
                    ],
                  ),
                  SizedBox(height: 10,),
                  
                  // body info
                  Row(
                    mainAxisAlignment:MainAxisAlignment.spaceBetween,
                    children: [
                      buildInfoBadge("Welcome"),
                      buildInfoBadge("to"),
                      buildInfoBadge("dotted"),
                    ],
                  )
                  
                ],
              ),
            ),
          );
        },
        
      )

    );
  }

  Widget buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 35),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEAEA),
        borderRadius: BorderRadius.circular(30),
      ),

      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color.fromARGB(255, 151, 151, 151),
        ),
      ),
    );
  }
}