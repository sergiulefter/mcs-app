import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic method to get a collection
  CollectionReference getCollection(String collectionPath) {
    return _firestore.collection(collectionPath);
  }

  // Generic method to get a document
  DocumentReference getDocument(String collectionPath, String docId) {
    return _firestore.collection(collectionPath).doc(docId);
  }

  // Add a document to a collection
  Future<String> addDocument(String collectionPath, Map<String, dynamic> data) async {
    try {
      DocumentReference docRef = await _firestore.collection(collectionPath).add(data);
      return docRef.id;
    } catch (e) {
      throw 'Error adding document: $e';
    }
  }

  // Set a document with a specific ID
  Future<void> setDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set(
            data,
            SetOptions(merge: merge),
          );
    } catch (e) {
      throw 'Error setting document: $e';
    }
  }

  // Update a document
  Future<void> updateDocument(
    String collectionPath,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
    } catch (e) {
      throw 'Error updating document: $e';
    }
  }

  // Delete a document
  Future<void> deleteDocument(String collectionPath, String docId) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      throw 'Error deleting document: $e';
    }
  }

  // Get a single document
  Future<DocumentSnapshot> getDocumentById(String collectionPath, String docId) async {
    try {
      return await _firestore.collection(collectionPath).doc(docId).get();
    } catch (e) {
      throw 'Error getting document: $e';
    }
  }

  // Get all documents in a collection
  Future<QuerySnapshot> getAllDocuments(String collectionPath) async {
    try {
      return await _firestore.collection(collectionPath).get();
    } catch (e) {
      throw 'Error getting documents: $e';
    }
  }

  // Stream a single document
  Stream<DocumentSnapshot> streamDocument(String collectionPath, String docId) {
    return _firestore.collection(collectionPath).doc(docId).snapshots();
  }

  // Stream all documents in a collection
  Stream<QuerySnapshot> streamCollection(String collectionPath) {
    return _firestore.collection(collectionPath).snapshots();
  }

  // Query documents with where clause
  Future<QuerySnapshot> queryDocuments(
    String collectionPath, {
    required String field,
    required dynamic isEqualTo,
  }) async {
    try {
      return await _firestore
          .collection(collectionPath)
          .where(field, isEqualTo: isEqualTo)
          .get();
    } catch (e) {
      throw 'Error querying documents: $e';
    }
  }

  // Stream query with where clause
  Stream<QuerySnapshot> streamQuery(
    String collectionPath, {
    required String field,
    required dynamic isEqualTo,
  }) {
    return _firestore
        .collection(collectionPath)
        .where(field, isEqualTo: isEqualTo)
        .snapshots();
  }
}
