import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/chat_provider.dart';

class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: const AIChatView(),
    );
  }
}

class AIChatView extends StatefulWidget {
  const AIChatView({super.key});

  @override
  State<AIChatView> createState() => _AIChatViewState();
}

class _AIChatViewState extends State<AIChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ChatProvider>(context);

    // After build completes, scroll down
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Financial Assistant'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final msg = provider.messages[index];
                return _ChatBubble(
                  text: msg.text,
                  isUser: msg.isUser,
                  theme: theme,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
              },
            ),
          ),
          
          if (provider.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'AI is typing...', 
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1200.ms, color: theme.colorScheme.primary.withOpacity(0.2))
                ],
              ),
            ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'e.g., Spent 500 on lunch...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (val) {
                        provider.sendMessage(val);
                        _controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      provider.sendMessage(_controller.text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final ThemeData theme;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.theme,
  });

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  bool _showCopy = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    setState(() => _showCopy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => setState(() => _showCopy = !_showCopy),
        child: Column(
          crossAxisAlignment: widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isUser ? widget.theme.colorScheme.primary : widget.theme.colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(widget.isUser ? 20 : 0),
                      bottomRight: Radius.circular(widget.isUser ? 0 : 20),
                    ),
                    boxShadow: [
                      if (!widget.isUser)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                    ],
                  ),
                  child: SelectionArea(
                    child: Text(
                      widget.text,
                      style: widget.theme.textTheme.bodyMedium?.copyWith(
                        color: widget.isUser ? Colors.white : widget.theme.textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                if (_showCopy)
                  Positioned(
                    top: -10,
                    right: widget.isUser ? null : -10,
                    left: widget.isUser ? -10 : null,
                    child: GestureDetector(
                      onTap: _copyToClipboard,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: widget.theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: widget.theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack).fadeIn(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
