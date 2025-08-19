import 'package:flutter/material.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:fluttertoast/fluttertoast.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user.dart';


class FirebaseAuthService{
  //firebaseAuth instance
  final FirebaseAuth _fbAuth = FirebaseAuth.instance;
  
  Future<UserModel?> signUp({required String username, required String email, required String password }) async{
    try{
      UserCredential result = await _fbAuth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // save to firestore
      if (user != null){
        // Create a document in the 'users' collection with the user's UID as the document ID
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'bio': 'I love dotted.',
          'profile_picture_url': '',
          'created_at': FieldValue.serverTimestamp(),
        });
        
        final newUser = UserModel(
          uid: user.uid,
          email: email,
          username: username,
          bio: 'I love dotted.',
          profilePictureUrl: '',
        );

        debugPrint("New user created: ${newUser.toMap()}");
        return newUser;
      }

      return null;
    }

    on FirebaseAuthException catch(e){
      Fluttertoast.showToast(msg: e.message ?? "Signup failed", gravity: ToastGravity.TOP);
      return null;
    }

    catch(e){
      Fluttertoast.showToast(msg: "Something went wrong", gravity: ToastGravity.TOP);
      return null;
    }
    
  }

  Future<UserModel?> signIn({required String email, required String password}) async {
    try {
      UserCredential ucred = await _fbAuth.signInWithEmailAndPassword( email: email, password: password);
      User? user = ucred.user;
      debugPrint("Signed in successfully! UID: ${user?.uid}");

      // return user;
      if (user != null){
        // Fetch user data from Firestore
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          debugPrint("Fetched user data: ${doc.data()}");
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }

        else {
          debugPrint("No user document found for UID: ${user.uid}");
        }

      }
      return null;
    }

    on FirebaseAuthException catch(e){
      Fluttertoast.showToast(msg: e.message ?? "Login failed", gravity: ToastGravity.TOP);
      return null;
    }

    catch (e) {
      Fluttertoast.showToast(msg: "Something went wrong", gravity: ToastGravity.TOP);
      return null;
    }

  }

  Future<void> signOut() async{
    User? user1 = _fbAuth.currentUser;
    debugPrint("logging out! UID: ${user1?.uid}");
    await _fbAuth.signOut();
    User? user2 = _fbAuth.currentUser;
    Fluttertoast.showToast(msg: "Successful Signout", gravity: ToastGravity.TOP);
    debugPrint("loging out! UID: ${user2?.uid}");
    
  }

  


}