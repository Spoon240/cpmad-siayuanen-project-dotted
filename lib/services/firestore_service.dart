import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import '../model/user.dart';
import 'package:fl_chart/fl_chart.dart';

class FirestoreService {
  // Initializes the Firestore instance. Used to interact with the database. Allow u to be connected to be the database, allowing u to read and write data
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // returns a UserModel object, or null if the user doesn't exist or there's an error.
  Future<UserModel?> fetchCurrentUserProfile() async{
    try{
      // fetches the currently logged-in user from Firebase Authentication.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // retrive all data that is related to the user.uid
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists){
        print("Fetch user data: ${doc.data()}");
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      else{
        print("User Document not found");
        return null;
      }

    }
    catch(e){
      print("Error fetching user profile: $e");
      return null;
    }
  } // profile page

  Future<void> updateUserProfile({required String username, required String bio}) async{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'username': username,
      'bio': bio,
    });

    debugPrint("User profile updated: username = $username, bio = $bio");
  } // edit profile page


  Future<String?> fetchProfilePictureUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (doc.exists) {
      return doc.data()?['profile_picture_url'] as String?;
    }
    return null;
  }


  Future<void> saveCalorieGoal({required double totalCalories, required double carbsPercentage, required double proteinPercentage, required double fatPercentage}) async{
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final carbsCals = totalCalories * (carbsPercentage / 100);
    final proteinCals = totalCalories * (proteinPercentage / 100);
    final fatCals = totalCalories * (fatPercentage / 100);

    final carbsGrams = carbsCals / 4;
    final proteinsGrams = proteinCals / 4;
    final fatsGrams = fatCals / 9;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('goals').doc('current').set({
      'calorieGoals': {
        'totalCalories': totalCalories,
        'carbs': {
          'percent': carbsPercentage,
          'grams': carbsGrams,
          'calories': carbsCals,
        },
        'protein': {
          'percent': proteinPercentage,
          'grams': proteinsGrams,
          'calories': proteinCals,
        },
        'fat': {
          'percent': fatPercentage,
          'grams': fatsGrams,
          'calories': fatCals,
        },
        'createdAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  } // for setting macro goals in home and as the starting page

  Future<bool> userHasCalorieGoals(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('goals').doc('current').get();
    return doc.exists;
  } // check for goals

  Future<Map<String, dynamic>?> fetchCurrentCalorieGoals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('goals').doc('current').get();

    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>?;
    // Expect data?['calorieGoals'] to exist based on your save function
    return (data?['calorieGoals'] as Map<String, dynamic>?);
  } // fetch caloric goal



  Future<Map<String, dynamic>?> getMacroGoals(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('goals').doc('current').get();
    return doc.data()?['calorieGoals'];
  } // get specific goals


  Future<void> saveUserWeight(double weight) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final dateId = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    // print("asad");
    // print(now);
    // print(dateId);

  
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('weights').doc(dateId).set({
      'weight': weight,
      'timestamp': FieldValue.serverTimestamp(),
    });
  } // logging weight

  Future<List<FlSpot>> getUserWeightSpots() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return []; // if no logs return empty list

    final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('weights').orderBy('timestamp').get();

    List<FlSpot> spots = []; // holds all the FlSpot(x, y) points to display on the chart
    int index = 0; // xIndex tracks how many points we’ve added so far (used as the X-axis value)

    for (var doc in snapshot.docs) {
      final data = doc.data();  // { 'weight': 65.0, 'timestamp': Timestamp(...)}
      final weight = data['weight'];

      if (weight is num) {
        spots.add(FlSpot(index.toDouble(), weight.toDouble()));
        index++;
      }
    }

    return spots;
  }

  // for creating food
  Future<void> addFood({required String name, required num protein, required num carbs,
    required num fats, required num calories, required bool autoCalc, required String origin
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No user logged in');
      
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('foods').add({
        'name': name.trim(),  // trim here so UI doesn’t have to
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'calories': calories,
        'calc_source': autoCalc ? 'auto' : 'manual',
        'type': 'food',
        'origin': origin,
        'created_at': FieldValue.serverTimestamp(),
      });
    } 
    catch (e) {
      debugPrint('Error adding food: $e');
      rethrow;
    }
  }

  String _norm(String raw) => raw.trim().replaceAll(RegExp(r'[\s-]'), ''); // Normalize but keep leading zeros
  Future<Map<String, dynamic>?> getBarcodeFood(String rawCode) async {
    final code = _norm(rawCode);
    if (code.isEmpty) return null;

    // Use doc id == barcode for O(1) lookup
    final snap = await FirebaseFirestore.instance.collection('barcodes').doc(code).get();
    if (!snap.exists) return null;

    final data = snap.data()!;
      debugPrint('Error adding food: $data');
    
    return {'id': snap.id, ...data};
  }

  Future<List<Map<String, dynamic>>> searchBarcodesByPrefix(String prefix) async {
    final normalized = prefix.trim();
    if (normalized.isEmpty) return [];

    final query = await FirebaseFirestore.instance
        .collection('barcodes')
        .orderBy('barcode')
        .startAt([normalized])
        .endAt([normalized + '\uf8ff'])
        .limit(10)
        .get();

    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> addExercise({required String name, required int caloriesBurned, required String intensity}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises').add({
      'type': 'exercise',
      'name': name.trim(),
      'name_lower': name.toLowerCase().trim(), // handy for search
      'calories_burned': caloriesBurned,
      'intensity': intensity,                  // store as-is
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchFoods() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No user logged in');

      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('foods').orderBy('created_at', descending: true).get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    } 
    catch (e) {
      print('Error fetching foods: $e');
      return [];
    }
      
  }
  
  Future<void> deleteFood(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('foods').doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> fetchExercises() async {
    try{
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('No user logged in');

      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises').orderBy('created_at', descending: true).get();

      return snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    }
    catch(e){
      print('Error fetching foods: $e');
      return [];
    }
  }

  Future<void> deleteExercise(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises').doc(id).delete();
  }

  Future<List<Map<String, dynamic>>> fetchGlobalFoods() async {
    final snap = await FirebaseFirestore.instance.collection('foods_public').get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> updateExercise({required String id, required String name, required int caloriesBurned, required String intensity}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('exercises').doc(id).update({
      'name': name.trim(),
      'name_lower': name.toLowerCase().trim(),
      'calories_burned': caloriesBurned,
      'intensity': intensity,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
  
  Future<void> updateFoodMacrosAuto({required String id,required num protein, required num carbs, required num fats, required int calories}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('foods').doc(id).update({
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'calories': calories,
      'calc_source': 'auto',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }



  String _dayKey(DateTime d) =>'${d.year.toString().padLeft(4,'0')}-''${d.month.toString().padLeft(2,'0')}-''${d.day.toString().padLeft(2,'0')}';

  Future<String> addDiaryEntry({required DateTime day, required String type, required String name, required num calories,
    String? meal,num? protein, num? carbs, num? fats,}) async {

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final dayDocId = '${day.year.toString().padLeft(4, '0')}-''${day.month.toStringAsFixed(0).padLeft(2, '0')}-''${day.day.toStringAsFixed(0).padLeft(2, '0')}';

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('diary').doc(dayDocId).set({
      'date': dayDocId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));


    final ref = await FirebaseFirestore.instance.collection('users').doc(uid).collection('diary').doc(dayDocId).collection('entries').add({
      'type': type,
      'name': name.trim(),
      'calories': calories,
      'meal': meal,
      'protein': protein ?? 0,
      'carbs': carbs ?? 0,
      'fats': fats ?? 0,
      'created_at': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  

  // STREAM (live updates)
  Stream<List<Map<String, dynamic>>> streamDiaryEntries(DateTime day) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user logged in');
      // Or return Stream.value([]) if you prefer a non-throwing variant.
    }

    final dayDocId = _dayKey(day); // you already have this helper

    return FirebaseFirestore.instance
      .collection('users').doc(uid).collection('diary')
      .doc(dayDocId).collection('entries').orderBy('created_at', descending: true).snapshots()
      .map((snap) => snap.docs
      .map((d) => {'id': d.id, ...d.data()})
      .toList());
  }

  // READ ONCE
  Future<List<Map<String, dynamic>>> fetchDiaryEntries(DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final dayDocId = _dayKey(day);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('diary')
        .doc(dayDocId)
        .collection('entries')
        .orderBy('created_at', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }


  // // get all history

  Future<List<Map<String, dynamic>>> fetchDiaryHistory({int maxDays = 30}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final diaryCol = FirebaseFirestore.instance.collection('users').doc(uid).collection('diary');

    List<QueryDocumentSnapshot<Map<String, dynamic>>> dayDocs;

    final daysSnap = await diaryCol.get();
    dayDocs = daysSnap.docs..sort((a, b) => b.id.compareTo(a.id)); // descending

    if (dayDocs.length > maxDays) {
      dayDocs = dayDocs.sublist(0, maxDays);
    }

    final results = <Map<String, dynamic>>[];

    for (final dayDoc in dayDocs) {
      final dateStr = dayDoc.id; // "YYYY-MM-DD"
      final entriesSnap = await dayDoc.reference.collection('entries').orderBy('created_at', descending: false).get();

      final entries = entriesSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      results.add({'date': dateStr, 'entries': entries});
    }

    return results;
  }

  // e.g. "2025-08-16" (your _dayKey format)
  Future<void> deleteDiaryEntry({required String dayDocId, required String entryId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    await FirebaseFirestore.instance.collection('users').doc(uid).collection('diary').doc(dayDocId).collection('entries').doc(entryId).delete();
  }


  // Optional: remove day doc if its 'entries' subcollection is empty
  Future<void> deleteEmptyDayDoc(String dayDocId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No user logged in');

    final dayRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('diary').doc(dayDocId);

    final entries = await dayRef.collection('entries').limit(1).get();
    if (entries.size == 0) {
      await dayRef.delete();
    }
  }


  // ai chat bot

  Future<String> createChat(String name, String context ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ref = await FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').add({
      'name': name,
      'context': context ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // Live stream of chats for the signed-in user.
  Stream<QuerySnapshot<Map<String, dynamic>>> chatsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> updateChat(String chatId, {required String name, required String context}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').doc(chatId).update({
      'name': name,
      'context': context,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Delete a chat and all its messages.
  Future<void> deleteChat(String chatId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chatDoc =  FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').doc(chatId);

    await _deleteFolderRecursive(FirebaseStorage.instance.ref().child('ai_chat_images/$uid/$chatId'));

    final msgs = await chatDoc.collection('messages').get();
    for (final msg in msgs.docs) {
      await msg.reference.delete();
    }
    await chatDoc.delete();
  }

  Future<void> _deleteFolderRecursive(Reference ref) async {
    final result = await ref.listAll();

    for (final item in result.items) {
      await item.delete();
    }

    for (final prefix in result.prefixes) {
      await _deleteFolderRecursive(prefix);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').doc(chatId).collection('messages').orderBy('timestamp', descending: true).snapshots();
  }


  /// Unified add message (user OR assistant). Handles optional image upload.
  Future<void> addMessage(String chatId, {required String role, required String text, File? imageFile}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final col = FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').doc(chatId).collection('messages');

    String? imageUrl;
    if (imageFile != null) {
      final path = 'ai_chat_images/$uid/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(path);
      final task = await ref.putFile(imageFile);
      imageUrl = await task.ref.getDownloadURL();
    }

    await col.add({
      'role': role,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  Future<String?> fetchCurrentUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final name = doc.data()?['username']?.toString();

    return name;
  }


  Future<List<Map<String, dynamic>>> fetchRecentMessages(String chatId, {int limit = 10,}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('ai_chats').doc(chatId)
        .collection('messages').orderBy('timestamp', descending: true).limit(limit).get();

    return snap.docs.reversed.map((d) => d.data()).toList(); // oldest → newest
  }
  
}










