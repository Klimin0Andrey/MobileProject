import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;

  DatabaseService({required this.uid});

  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection('users');

  // Временный метод - потом расширим
  Future<void> updateUserData(String sugars, String name, int strength) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'sugars': sugars,
      'strength': strength,
      'role': 'customer', // Роль по умолчанию
    });
  }
}