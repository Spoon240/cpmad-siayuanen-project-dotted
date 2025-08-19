import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


class EditProfilePage extends StatefulWidget {
  final String? username;
  final String? bio;
  const EditProfilePage({super.key, required this.username, required this.bio});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController bioController;

  // for profile
  File? _imageFile;
  String? profilePicUrl;
  bool isUploading = false;
  
  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.username);
    bioController = TextEditingController(text: widget.bio);

    _loadProfilePicture(); //Load image if already uploaded
  }

  Future<void> _loadProfilePicture() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('profile_picture_url')) {
      setState(() {
        profilePicUrl = doc['profile_picture_url'];
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker _picker = ImagePicker();
      debugPrint("Opening image picker...");
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      debugPrint("Image picker done");

      if (pickedFile == null) {
        debugPrint("No image selected.");
        return;
      }
      
      final file = File(pickedFile.path);
      setState(() {
        _imageFile = file;
        isUploading = true;
      });

      debugPrint("Uploading...");

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance.ref().child("profile_pics/$uid.jpg");

      debugPrint("Putting file to storage...");
      final uploadTask = await storageRef.putFile(file);
      debugPrint("Upload complete");

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint("Download URL: $downloadUrl");

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profile_picture_url': downloadUrl,
      });
      debugPrint("Firestore updated");

      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated!")),
      );
    } 
    catch (e) {
      debugPrint("Error during upload: $e");
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image.")),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),

      ),

      body: isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
            padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (profilePicUrl != null && profilePicUrl!.isNotEmpty
                              ? NetworkImage(profilePicUrl!)
                              : const AssetImage('images/profile-icon-placeholder.png')) as ImageProvider,
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Color.fromARGB(255, 44, 81, 73),
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                        onPressed: _pickAndUploadImage,

                      ),
                    )
                  ],
                ),
          
                Container(
                  alignment: Alignment.topLeft,
                  child: const Text("Username", style: TextStyle(fontFamily: 'Poppins', fontSize: 12),)
                ),
                _buildNormalField("Username", Icons.person_outline, usernameController),

                SizedBox(height: 10,),

                Container(
                  alignment: Alignment.topLeft,
                  child: const Text("Bio", style: TextStyle(fontFamily: 'Poppins', fontSize: 12),)
                ),

                _buildNormalField(
                  "Bio",
                  Icons.info_outline,
                  bioController,
                  maxLines: 3,
                  maxLength: 60, // adjust to fit your preferred max
                ),

                SizedBox(height: 25,),


                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updatedUsername = usernameController.text.trim();
                      final updatedBio = bioController.text.trim();

                      await FirestoreService().updateUserProfile(
                        username: updatedUsername,
                        bio: updatedBio,
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Profile updated successfully")),
                      );

                      Navigator.pop(context); 
                    }, // button logic

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B7E7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),
    );



  }
  
  Widget _buildNormalField( String label, IconData icon, TextEditingController controller, {int maxLines = 1, int? maxLength,}){
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
      decoration: InputDecoration(
        alignLabelWithHint: true, // Important for multi-line
        prefixIcon: Container(
          padding: EdgeInsets.fromLTRB(0, 0, 0, maxLines > 1 ? 32 : 0),
          child: Icon(icon, size: 20)
        ),
      
        hintText: label,
        counterText: "",
        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        filled: true,
        fillColor: Color(0xFFEAEAEA),
        contentPadding: const EdgeInsets.all(18),
        
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none
        )
      ),
    );
  }



}