import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../models/chat_message_model.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.sendMessage(text);
      
      // Save to Supabase
      final chatMessage = ChatMessageModel(
        id: '',
        userId: user.id,
        message: text,
        response: response,
        createdAt: DateTime.now(),
      );

      await ref.read(aiChatRepositoryProvider).saveChatMessage(chatMessage);
    } catch (e) {
      debugPrint("Chat AI Error: $e");
      // Save error message
      final chatMessage = ChatMessageModel(
        id: '',
        userId: user.id,
        message: text,
        response: "Sorry, I encountered an error: $e",
        createdAt: DateTime.now(),
      );
      await ref.read(aiChatRepositoryProvider).saveChatMessage(chatMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatStreamAsync = ref.watch(aiChatStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'SSA Assistant',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Futuristic Tech Background using workspace image
          Positioned.fill(
            child: Image.asset(
              'assets/images/study_laptop.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Immersive Ultra Dark Blur & Radial Neon Blue Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.98),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Immersive Chat Interface
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: chatStreamAsync.when(
                    data: (history) {
                      final List<ChatMessage> uiMessages = [];
                      for (var model in history) {
                        uiMessages.add(ChatMessage(text: model.message, isUser: true));
                        uiMessages.add(ChatMessage(text: model.response, isUser: false));
                      }

                      if (uiMessages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Start a conversation with your study assistant!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: uiMessages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == uiMessages.length) {
                            return const _TypingIndicator();
                          }
                          final msg = uiMessages[index];
                          return _MessageBubble(message: msg);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text('Error loading chat history: $err', style: const TextStyle(color: Colors.red))),
                  ),
                ),

                // Glassmorphic Input Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 110.0), // Padding to clear floating bottom navigation
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Ask a question or summarize notes...',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.black87,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: isUser 
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
          ),
          border: Border.all(
            color: isUser 
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFF2979FF).withValues(alpha: 0.35), // Cyan/Blue border for AI
            width: 1.2,
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: const Color(0xFF2979FF).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role indicator tag
                  Text(
                    isUser ? 'YOU' : 'SSA ASSISTANT',
                    style: TextStyle(
                      color: isUser 
                          ? Colors.white60 
                          : Theme.of(context).colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(context),
            const SizedBox(width: 4),
            _buildDot(context),
            const SizedBox(width: 4),
            _buildDot(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}
