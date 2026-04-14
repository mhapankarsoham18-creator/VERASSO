import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/features/messaging/views/chat_screen.dart';
import 'package:verasso/core/theme/neo_pixel_box.dart';
import 'package:verasso/features/messaging/services/messaging_service.dart';

class MockMessagingService implements MessagingService {
  @override
  Future<void> ensureKeysExist() async {}

  @override
  Future<String?> getConversationIdWithPeer(String peerId) async {
    return 'fake-conversation-id';
  }

  @override
  Future<String?> getPeerPublicKey(String peerId) async {
    return 'fake-public-key';
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String conversationId) async {
    return []; // Start with no messages
  }

  @override
  RealtimeChannel subscribeToMessages(String conversationId, void Function(Map<String, dynamic>) onMessage) {
    // Return a dummy channel (or null if we didn't type it nicely, but we can't easily return a fake RealtimeChannel without a client).
    // We can throw if we cast it, but let's just return a generic fake or throw since we don't await/need the returned channel except for dispose.
    throw UnimplementedError('Not needed in this simple mock');
  }
  
  @override
  Future<void> sendSecureMessage(String peerId, String plainText) async {
    // Just fake success
  }

  @override
  Future<String> decryptMessageRow(Map<String, dynamic> messageRow, String peerPublicKey) async {
    return 'decrypted fake message';
  }
}

// Alternatively, since subscribeToMessages returns RealtimeChannel which expects a Supabase client, we might hit an issue when calling unsubscribe.
// In ChatScreen, we do _subscription?.unsubscribe(). If we return null, we must change _subscription to RealtimeChannel? and it will pass.
// Wait, subscribeToMessages returns RealtimeChannel. In Mock we can just return a fake if we could, but let's see how ChatScreen handles it.
// Actually, RealtimeChannel is hard to mock because it's a concrete class. Since we only want to test the UI, returning null from subscribe might violate the type signature.

// Let's create a better mock using Mockito? No, let's just override subscribeToMessages to throw OR return something if needed. Wait, RealtimeChannel can be instantiated possibly.
// Or we can just change ChatScreen to not crash if subscribeToMessages throws in test.

class SimpleMockMessagingService implements MessagingService {
  @override
  Future<String> decryptMessageRow(Map<String, dynamic> messageRow, String peerPublicKey) async => 'fake';

  @override
  Future<void> ensureKeysExist() async {}

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String conversationId) async => [];

  @override
  Future<String?> getConversationIdWithPeer(String peerId) async => 'conv-id';

  @override
  Future<String?> getPeerPublicKey(String peerId) async => 'public-key';

  @override
  Future<void> sendSecureMessage(String peerId, String plainText) async {}

  @override
  RealtimeChannel subscribeToMessages(String conversationId, void Function(Map<String, dynamic> p1) onMessage) {
     // Because we cannot instantiate RealtimeChannel easily, we throw an exception that ChatScreen catches or we just return an instance using an empty dummy.
     // To avoid the error, since we don't strictly need to mock it, let's just let it be. But wait, Dart requires returning RealtimeChannel!
     throw UnimplementedError("Mocking RealtimeChannel is hard, let's see if we catch this in ChatScreen._initChat!");
  }
}

void main() {
  group('ChatScreen Widget Tests', () {
    testWidgets('ChatScreen displays PeerName and E2E Badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            peerId: 'uuid-1234',
            peerName: 'Siddhi',
            messagingService: SimpleMockMessagingService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the App Bar contains the Peer Name capitalized
      expect(find.text('SIDDHI'), findsOneWidget);

      // Verify E2E Encryption badge is strictly rendered for security confirmation
      expect(find.text('E2E ENCRYPTED'), findsOneWidget);
    });

    testWidgets('Inputting text adds message bubble to the list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(
            peerId: 'uuid-1234',
            peerName: 'Siddhi',
            messagingService: SimpleMockMessagingService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Transmit message hint
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Find the NeoPixelBox Send Button using the icon
      final sendButton = find.widgetWithIcon(NeoPixelBox, Icons.send);
      expect(sendButton, findsOneWidget);

      // Enter text
      await tester.enterText(textField, 'This is a test message to the peer.');
      
      // Tap the send button causing the internal _messages list to update
      await tester.tap(sendButton);
      await tester.pump(); // trigger set state

      // Verify the new message renders properly
      expect(find.text('This is a test message to the peer.'), findsOneWidget);
      expect(find.text('Now'), findsNothing); // It usually prints the time
    });
  });
}
