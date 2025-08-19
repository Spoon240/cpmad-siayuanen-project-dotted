class UserModel {
  String? uid;
  String? email;
  String? username;
  String? bio;
  String? profilePictureUrl;

  UserModel({
    this.uid,
    this.email,
    this.username,
    this.bio,
    this.profilePictureUrl,
  });

  // Construct from Firestore map
  // to constructor form
  UserModel.fromMap(Map<String, dynamic> data) {
    uid = data['uid'];
    email = data['email'];
    username = data['username'];
    bio = data['bio'] ?? 'I love dotted.';
    profilePictureUrl = data['profile_picture_url'];
  }

  // Convert to map to store in Firestore
  // to map form
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
    };
  }
}
