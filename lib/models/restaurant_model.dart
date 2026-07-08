import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/app_image.dart';

class Restaurant {
  final String id;
  final String name;
  final String category; // Maps to cuisine
  final String imageUrl;
  final String openingTime;
  final String closingTime;
  final double rating;
  final String priceLevel;
  final String deliveryFee;
  final String deliveryTime;
  final String pickupTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.openingTime,
    required this.closingTime,
    required this.rating,
    this.priceLevel = r'$$',
    this.deliveryFee = 'Rs.250.00',
    this.deliveryTime = '25-30 min',
    this.pickupTime = '10-15 min',
    this.createdAt,
    this.updatedAt,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? data['restaurantName'] ?? 'Unnamed Restaurant',
      category: data['category'] ?? data['cuisine'] ?? 'General',
      imageUrl: resolveImageSource(data),
      openingTime: data['openingTime'] ?? '09:00 AM',
      closingTime: data['closingTime'] ?? '10:00 PM',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      priceLevel: data['priceLevel'] ?? r'$$',
      deliveryFee: data['deliveryFee'] ?? 'Rs.250.00',
      deliveryTime: data['deliveryTime'] ?? '25-30 min',
      pickupTime: data['pickupTime'] ?? '10-15 min',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'rating': rating,
      'priceLevel': priceLevel,
      'deliveryFee': deliveryFee,
      'deliveryTime': deliveryTime,
      'pickupTime': pickupTime,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
