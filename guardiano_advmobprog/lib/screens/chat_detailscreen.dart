import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/chat_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

final ChatService chatService = ChatService();
final UserService userService = UserService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String?> _currentUserIdFuture;
  bool _isSending = false;

  // Stores pending local messages while waiting for slow connection writes to settle.
  final List<Map<String, dynamic>> _pendingLocalMessages = [];

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  // Fetches current user UID with Firebase Auth fallback.
  Future<String?> _getCurrentUserId() async {
    try {
      final userData = await userService.getUserData();
      final uid = userData['uid']?.toString();
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
    } catch (_) {}

    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Helper method to verify active internet connectivity.
  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Formats Firestore Timestamp into "hh:mm AM/PM" format.
  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final DateTime dt = timestamp.toDate();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return 'Just now';
  }

  // Sends message to Firestore, blocking offline sends and showing pending states for slow connections.
  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    // Check offline state before proceeding.
    final bool isConnected = await _hasInternetConnection();
    if (!isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot send message. Please check your internet connection.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final Map<String, dynamic> pendingMsg = {
      'id': tempId,
      'senderId': currentUserId,
      'message': text,
      'timestamp': Timestamp.now(),
      'isPending': true,
    };

    setState(() {
      _isSending = true;
      _pendingLocalMessages.insert(0, pendingMsg);
    });

    _msgCtrl.clear();
    _msgFocus.requestFocus();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    try {
      await chatService.sendMessage(receiverId, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _pendingLocalMessages.removeWhere((msg) => msg['id'] == tempId);
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId =
        (widget.tappedUser['uid'] ?? widget.tappedUser['docId'] ?? '')
            .toString();
    final tappedFirstName = (widget.tappedUser['firstName'] ?? '').toString();
    final tappedLastName = (widget.tappedUser['lastName'] ?? '').toString();
    final tappedUserName = '$tappedFirstName $tappedLastName'.trim();
    final tappedEmail = (widget.tappedUser['email'] ?? '').toString();

    return FutureBuilder<String?>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (snap.hasError ||
            !snap.hasData ||
            snap.data == null ||
            snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user session details.')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            elevation: 1,
            titleSpacing: 0,
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: CustomText(
                        text: tappedFirstName.isNotEmpty
                            ? tappedFirstName[0].toUpperCase()
                            : '?',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: tappedUserName.isNotEmpty
                            ? tappedUserName
                            : 'Chat Detail',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomText(
                        text: tappedEmail,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Enhancement 3: Animated StreamBuilder displaying server messages and pending offline/slow connection messages.
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                        ),
                      );
                    }

                    final serverDocs = snapshot.data?.docs ?? [];
                    final List<Map<String, dynamic>> combinedList = [];

                    // Add pending messages during slow connection writes.
                    for (var pending in _pendingLocalMessages) {
                      combinedList.add(pending);
                    }

                    for (var doc in serverDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      data['isPending'] = false;
                      combinedList.add(data);
                    }

                    if (combinedList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mark_chat_read_outlined,
                              size: 48.sp,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8.h),
                            CustomText(
                              text: 'No messages yet. Say hello!',
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 14.w,
                      ),
                      itemCount: combinedList.length,
                      itemBuilder: (context, index) {
                        final data = combinedList[index];
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final timestamp = data['timestamp'];
                        final isPending = data['isPending'] == true;
                        final isMe = senderId == currentUserId;

                        // Enhancement 3: Smooth UI slide & fade transition for message bubbles.
                        return TweenAnimationBuilder<double>(
                          key: ValueKey(data['id'] ?? index),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, (1 - value) * 18),
                                child: child,
                              ),
                            );
                          },
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 14.w,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.74,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18.r),
                                  topRight: Radius.circular(18.r),
                                  bottomLeft: isMe
                                      ? Radius.circular(18.r)
                                      : Radius.circular(3.r),
                                  bottomRight: isMe
                                      ? Radius.circular(3.r)
                                      : Radius.circular(18.r),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: msgText.isNotEmpty
                                        ? msgText
                                        : '(empty)',
                                    fontSize: 14.sp,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                  SizedBox(height: 4.h),
                                  // Enhancement 3: Displays "sending..." during slow connection or double checkmarks when delivered.
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isPending) ...[
                                        CustomText(
                                          text: 'sending...',
                                          fontSize: 10.sp,
                                          color: Colors.white70,
                                        ),
                                        SizedBox(width: 4.w),
                                        SizedBox(
                                          width: 10.sp,
                                          height: 10.sp,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white70),
                                              ),
                                        ),
                                      ] else ...[
                                        CustomText(
                                          text: _formatTime(timestamp),
                                          fontSize: 10.sp,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                        if (isMe) ...[
                                          SizedBox(width: 4.w),
                                          Icon(
                                            Icons.done_all,
                                            size: 14.sp,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom chat input bar
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) =>
                              _send(currentUserId, tappedUserId),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade500,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18.w,
                              vertical: 11.h,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.r),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            size: 18.sp,
                            color: Colors.white,
                          ),
                          onPressed: () => _send(currentUserId, tappedUserId),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
