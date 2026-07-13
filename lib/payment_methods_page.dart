import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_notification.dart';

/// Saved payment methods (cards added during checkout). The user can remove
/// cards here — except while an order is still running, since that card may
/// be needed to complete the active payment.
class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  static const _accent = Color(0xFF4A22A8);
  static const List<String> _activeStatuses = [
    'confirmed',
    'processing',
    'received',
    'preparing',
    'ready',
    'finding_rider',
    'picked_up',
    'on_the_way',
  ];

  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cardsSub;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _loading = false;
      return;
    }
    _cardsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('payment_methods')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _cards = snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        _loading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _cardsSub?.cancel();
    super.dispose();
  }

  Future<bool> _hasOngoingOrder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders_sl')
          .where('userId', isEqualTo: uid)
          .where('orderStatus', whereIn: _activeStatuses)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _removeCard(Map<String, dynamic> card) async {
    // A card cannot be removed while an order is still in progress.
    if (await _hasOngoingOrder()) {
      showAppNotification(
        title: 'Order in progress',
        message:
            'You cannot remove a payment method while an order is running. Please wait until it is delivered.',
        type: NotificationType.warning,
      );
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove card?'),
        content: Text(
            'Remove ${card['brand'] ?? 'card'} •••• ${card['last4'] ?? ''} from your saved payment methods?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payment_methods')
          .doc(card['id'].toString())
          .delete();
      showAppNotification(
        title: 'Card removed',
        message: 'The payment method was removed from your account.',
        type: NotificationType.success,
      );
    } catch (e) {
      showAppNotification(
        title: 'Could not remove',
        message: e.toString(),
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Payment Methods',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.credit_card_off_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No saved cards yet.\nCards you save at checkout appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E2F5)),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.credit_card,
                              color: _accent, size: 22),
                        ),
                        title: Text(
                          '${card['brand'] ?? 'Card'} •••• ${card['last4'] ?? ''}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          (card['currency'] ?? 'LKR').toString(),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _removeCard(card),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
