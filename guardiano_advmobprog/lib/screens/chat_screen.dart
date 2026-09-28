import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// services
import '../services/chat_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// screens
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  String? _currentUserEmail;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();

    // Enhancement 2: Listens for text input changes in the search bar to update the search filter in real-time.
    _searchChatController.addListener(() {
      setState(() {
        _searchText = _searchChatController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await _userService.getUserData();
    setState(() {
      _currentUserEmail = userData['email'];
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Messages',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Search bar input field.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 23.w),
              child: TextField(
                controller: _searchChatController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search chat....',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: (_searchChatController.text.isNotEmpty)
                      ? IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            _searchChatController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // Users Stream builder
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'Error loading users',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No users found!',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                // Enhancement 1 & 2: Filter user list by self-exclusion and active search query.
                final users = snapshot.data!.where((user) {
                  final email = (user['email'] ?? '').toString();
                  final firstName = (user['firstName'] ?? '').toString();
                  final lastName = (user['lastName'] ?? '').toString();

                  // Enhancement 1: Exclude currently logged in user.
                  if (_currentUserEmail != null &&
                      _currentUserEmail!.isNotEmpty &&
                      email.toLowerCase() == _currentUserEmail!.toLowerCase()) {
                    return false;
                  }

                  // Enhancement 2: Match against search query (first name, last name, or email).
                  if (_searchText.isNotEmpty) {
                    final matchesFirstName = firstName.toLowerCase().contains(
                      _searchText,
                    );
                    final matchesLastName = lastName.toLowerCase().contains(
                      _searchText,
                    );
                    final matchesEmail = email.toLowerCase().contains(
                      _searchText,
                    );

                    return matchesFirstName || matchesLastName || matchesEmail;
                  }

                  return true;
                }).toList();

                if (users.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No messages found...',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail ?? '',
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: CustomText(
                              text:
                                  user['firstName'] != null &&
                                      user['firstName'].toString().isNotEmpty
                                  ? user['firstName'][0].toUpperCase()
                                  : '?',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: CustomText(
                            text: user['firstName'] ?? 'Unknown',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: CustomText(
                            text: user['email'] ?? 'No email',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
