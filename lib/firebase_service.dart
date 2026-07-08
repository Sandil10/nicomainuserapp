import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _productsCollection = 'products_sl';

  // Add product to Firestore
  static Future<bool> addProduct({
    required String name,
    required String description,
    required double price,
    required String uom,
    required String currency,
    required bool hasImage,
  }) async {
    try {
      await _firestore.collection(_productsCollection).add({
        'name': name,
        'description': description,
        'price': price,
        'uom': uom,
        'currency': currency,
        'hasImage': hasImage,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  // Get all products from Firestore
  static Stream<QuerySnapshot> getProducts() {
    return _firestore
        .collection(_productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete product from Firestore
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_productsCollection).doc(productId).delete();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }
}
