import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'app_localization.dart';
import 'app_notification.dart'; // ✅ Import app_notification

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSending = false;
  bool _isAdminTyping = false;
  List<Map<String, dynamic>> _messages = [];
  String? _userDisplayName;
  String? _userId;
  String? _chatId;
  StreamSubscription<DocumentSnapshot>? _chatSubscription;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      await AppLocalization.initialize();
      await _setupUserProfile();
      await _initializeFirebaseChat();
      await _loadChatHistory();
      _startListeningToChat();
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _messages = [_getWelcomeMessage()];
      });
    }
  }

  Future<void> _setupUserProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        currentUser = userCredential.user;
      }

      if (currentUser != null) {
        setState(() {
          _userId = currentUser!.uid;
          _userDisplayName = AppLocalization.getText('guestUser');
        });
      }
    } catch (e) {
      print('Authentication failed: $e');
      final prefs = await SharedPreferences.getInstance();
      String? localUserId = prefs.getString('local_user_id');

      if (localUserId == null) {
        localUserId = 'LOCAL_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('local_user_id', localUserId);
      }

      setState(() {
        _userId = localUserId;
        _userDisplayName = AppLocalization.getText('guestUser');
      });
    }
  }

  Future<void> _initializeFirebaseChat() async {
    if (_userId == null) return;

    try {
      final chatQuery = await _firestore
          .collection('chats_sl')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        _chatId = chatQuery.docs.first.id;
        print('Found existing chat: $_chatId');
      } else {
        final newChatData = {
          'userId': _userId!,
          'userName': _userDisplayName ?? AppLocalization.getText('guestUser'),
          'userEmail': '',
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': 'system',
          'unreadCount': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'open',
          'messages': [],
          'userTyping': false,
          'adminTyping': false,
        };

        final chatDoc =
            await _firestore.collection('chats_sl').add(newChatData);
        _chatId = chatDoc.id;
        print('Created new chat: $_chatId');
      }
    } catch (e) {
      print('Firebase chat initialization error: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    List<Map<String, dynamic>> chatMessages = [_getWelcomeMessage()];

    if (_chatId == null) {
      setState(() {
        _messages = chatMessages;
      });
      return;
    }

    try {
      final chatDoc =
          await _firestore.collection('chats_sl').doc(_chatId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final messagesData = data['messages'] as List<dynamic>? ?? [];

        for (var messageData in messagesData) {
          chatMessages.add({
            'id': messageData['id'] ?? '',
            'text': messageData['content'] ?? '',
            'isFromUser': messageData['senderType'] == 'user',
            'timestamp': messageData['timestamp'] != null
                ? (messageData['timestamp'] as Timestamp)
                    .toDate()
                    .toIso8601String()
                : DateTime.now().toIso8601String(),
            'senderName': messageData['senderName'] ?? '',
            'status': 'delivered',
            'type':
                messageData['messageType'] == 'system' ? 'system' : 'message',
          });
        }
      }

      setState(() {
        _messages = chatMessages;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _messages = chatMessages;
      });
    }
  }

  Map<String, dynamic> _getWelcomeMessage() {
    return {
      'id': 'welcome_msg',
      'text': AppLocalization.getText('welcomeMessage', params: {
        'userName': _userDisplayName ?? AppLocalization.getText('guestUser')
      }),
      'isFromUser': false,
      'timestamp': DateTime.now().toIso8601String(),
      'senderName': AppLocalization.getText('nicoSupport'),
      'type': 'welcome',
    };
  }

  void _startListeningToChat() {
    if (_chatId == null) return;

    _chatSubscription?.cancel();

    _chatSubscription =
        _firestore.collection('chats_sl').doc(_chatId).snapshots().listen(
      (snapshot) {
        if (!mounted || !snapshot.exists) return;

        try {
          final data = snapshot.data() as Map<String, dynamic>;
          final messagesData = data['messages'] as List<dynamic>? ?? [];
          final adminTyping = data['adminTyping'] as bool? ?? false;

          List<Map<String, dynamic>> chatMessages = [_getWelcomeMessage()];

          for (var messageData in messagesData) {
            chatMessages.add({
              'id': messageData['id'] ?? '',
              'text': messageData['content'] ?? '',
              'isFromUser': messageData['senderType'] == 'user',
              'timestamp': messageData['timestamp'] != null
                  ? (messageData['timestamp'] as Timestamp)
                      .toDate()
                      .toIso8601String()
                  : DateTime.now().toIso8601String(),
              'senderName': messageData['senderName'] ?? '',
              'status': 'delivered',
              'type':
                  messageData['messageType'] == 'system' ? 'system' : 'message',
            });
          }

          setState(() {
            _messages = chatMessages;
            _isAdminTyping = adminTyping;
          });

          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        } catch (e) {
          print('Error processing snapshot: $e');
        }
      },
      onError: (error) {
        print('Firestore listener error: $error');
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    _setUserTyping(false);

    try {
      await _saveMessageToFirebase(text);
      if (mounted) {
        // ✅ Show top notification for success
        showAppNotification(
          title: AppLocalization.getText('success'),
          message: AppLocalization.getText('messageSentSuccessfully'),
          type: NotificationType.success,
        );
      }
    } catch (e) {
      print('Send message error: $e');
      if (mounted) {
        // ✅ Show top notification for error
        showAppNotification(
          title: AppLocalization.getText('error'),
          message: AppLocalization.getText('failedToSendMessage',
              params: {'error': e.toString()}),
          type: NotificationType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }

    HapticFeedback.lightImpact();
  }

  Future<void> _saveMessageToFirebase(String messageText) async {
    if (_chatId == null || _userId == null) {
      throw Exception('Chat not initialized');
    }

    print('Saving message: $messageText');

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${_userId}';
    final currentTimestamp = Timestamp.now();

    final newMessage = {
      'id': messageId,
      'senderId': _userId!,
      'senderType': 'user',
      'senderName': _userDisplayName ?? AppLocalization.getText('guestUser'),
      'content': messageText,
      'messageType': 'text',
      'timestamp': currentTimestamp,
      'isRead': false,
    };

    await _firestore.collection('chats_sl').doc(_chatId).update({
      'messages': FieldValue.arrayUnion([newMessage]),
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': 'user',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
      'isActive': true,
      'userTyping': false,
    });

    print('Message saved successfully');
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      _setUserTyping(true);
      _typingTimer?.cancel();
      _typingTimer =
          Timer(const Duration(seconds: 2), () => _setUserTyping(false));
    } else {
      _setUserTyping(false);
    }
  }

  void _setUserTyping(bool isTyping) {
    if (_chatId == null) return;

    _firestore.collection('chats_sl').doc(_chatId).update({
      'userTyping': isTyping,
      'updatedAt': FieldValue.serverTimestamp(),
    }).catchError((error) {
      print('Typing status update error: $error');
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.positions.isNotEmpty) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4A22A8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalization.getText('supportChatTitle'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isAdminTyping
                      ? AppLocalization.getText('adminIsTyping')
                      : AppLocalization.getText('connectedAs', params: {
                          'userName': _userDisplayName ??
                              AppLocalization.getText('guestUser')
                        }),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isAdminTyping
                        ? const Color(0xFFFFEB3B)
                        : Colors.white70,
                    fontStyle:
                        _isAdminTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromUser = message['isFromUser'] ?? false;
    final messageType = message['type'] ?? '';
    final text = message['text'] ?? '';
    final timestamp = DateTime.parse(message['timestamp']);
    final status = message['status'];
    final senderName = message['senderName'] ?? '';

    if (messageType == 'system') {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4A22A8),
              child: const Icon(
                Icons.support_agent,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isFromUser ? const Color(0xFF4A22A8) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isFromUser ? 18 : 4),
                  bottomRight: Radius.circular(isFromUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromUser && messageType == 'welcome') ...[
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A22A8),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isFromUser ? Colors.white : const Color(0xFF1F2937),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isFromUser
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                      if (isFromUser && status != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          status == 'delivered'
                              ? Icons.done_all
                              : status == 'pending'
                                  ? Icons.access_time
                                  : Icons.error_outline,
                          color: status == 'delivered'
                              ? Colors.white
                              : Colors.white70,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6B7280),
              child: Text(
                _userDisplayName?.isNotEmpty == true
                    ? _userDisplayName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: _onTextChanged,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalization.getText('typeYourMessage'),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF4A22A8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
