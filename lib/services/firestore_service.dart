import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:field_ready/data/combine_data.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<CombineData>> getCombines() async {
    try {
      final snapshot = await _db.collection('combineSpecs').get();
      return snapshot.docs.map((doc) => CombineData.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting combines: $e');
      return [];
    }
  }
}
