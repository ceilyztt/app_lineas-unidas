import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../providers/ride_provider.dart';
import '../../models/message_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  late String _rideId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rideId = ModalRoute.of(context)!.settings.arguments as String;
    NotificationService.isChatOpen = true;
    NotificationService.activeRideId = _rideId;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.firebaseUser != null) {
      _firestoreService.markChatAsRead(_rideId, authProvider.firebaseUser!.uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    NotificationService.isChatOpen = false;
    NotificationService.activeRideId = null;
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.firebaseUser!.uid;

    String? recipientId;
    try {
      final rideProvider = Provider.of<RideProvider>(context, listen: false);
      final ride = rideProvider.currentRide;
      if (ride != null) {
        recipientId = (userId == ride.clientId) ? ride.driverId : ride.clientId;
      }
    } catch (_) {}

    // Recuperación dinámica de Firestore si no está cargado localmente
    if (recipientId == null) {
      try {
        final ride = await _firestoreService.getRide(_rideId);
        if (ride != null) {
          recipientId = (userId == ride.clientId) ? ride.driverId : ride.clientId;
        }
      } catch (e) {
        debugPrint("Error fetching ride for recipient: $e");
      }
    }

    final message = MessageModel(
      id: '', // Firestore genera el ID
      senderId: userId,
      text: text,
      timestamp: DateTime.now(),
    );

    _messageController.clear();
    await _firestoreService.sendMessage(_rideId, message);

    if (recipientId != null && recipientId.isNotEmpty) {
      try {
        final senderName = authProvider.userModel?.name ?? authProvider.driverModel?.name ?? 'Mensaje nuevo';
        NotificationService().sendPushNotification(
          recipientId: recipientId,
          title: '$senderName 💬',
          body: text,
          data: {'rideId': _rideId},
        );
      } catch (e) {
        debugPrint("Error sending chat push: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.firebaseUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat del Viaje'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.streamMessages(_rideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aún.\n¡Escribe algo para empezar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textGrey),
                    ),
                  );
                }

                final messages = snapshot.data!;

                // Marcar como leídos en tiempo real al recibir nuevos mensajes
                if (messages.isNotEmpty && messages.last.senderId != currentUserId) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _firestoreService.markChatAsRead(_rideId, currentUserId);
                  });
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? AppTheme.backgroundColor : AppTheme.textWhite,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMe 
                  ? AppTheme.backgroundColor.withValues(alpha: 0.7) 
                  : AppTheme.textGrey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: AppTheme.textGrey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppTheme.backgroundColor),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
