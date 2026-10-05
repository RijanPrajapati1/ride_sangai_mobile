import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors_ext.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../utils/error_message.dart';
import '../providers/message_providers.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Loading the messages already marks the chat read on the server; this
    // makes sure the inbox badges refresh once we're in.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(messageActionsControllerProvider).markRead(widget.conversationId);
      } catch (_) {
        // Not worth bothering the rider about; the next inbox refresh catches up.
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textController.clear();
    try {
      await ref.read(messageActionsControllerProvider).sendMessage(conversationId: widget.conversationId, text: text);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // Give the text back so the rider can retry.
      if (_textController.text.isEmpty) _textController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(conversationMessagesProvider(widget.conversationId));
    final conversation = ref.watch(conversationProvider(widget.conversationId)).value;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: conversation == null ? null : () => context.push(RouteNames.userProfilePath(conversation.userId)),
          child: Row(
            children: [
              AppAvatar(imageUrl: conversation?.userAvatarUrl, name: conversation?.userName ?? '', size: 36),
              const SizedBox(width: 10),
              Text(conversation?.userName ?? 'Conversation'),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(messageActionsControllerProvider).refreshConversation(widget.conversationId),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, st) => AppErrorWidget(
                message: errorMessage(e),
                onRetry: () => ref.invalidate(conversationMessagesProvider(widget.conversationId)),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Say hello!',
                    message: 'This is the start of your conversation.',
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppDimensions.spaceMd),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => MessageBubble(message: messages[index]),
                );
              },
            ),
          ),
          _Composer(controller: _textController, onSend: _send, sending: _sending),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;

  const _Composer({required this.controller, required this.onSend, required this.sending});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: context.appColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(hintText: 'Type a message…'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: sending ? null : onSend,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
