import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../entities/message.dart';

/// A controller that handles the communication of [Message] objects with Firestore.
///
/// This controller is responsible for sending messages and listening for real-time
/// updates for a specific match room.
class FirestoreMessageController {
  static final _log = Logger('FirestoreMessageController');

  /// The instance of Firebase Firestore to use.
  final FirebaseFirestore instance;

  /// The ID of the match room.
  final String roomId;

  /// A reference to the 'messages' collection for this [roomId].
  ///
  /// This uses a `withConverter` to automatically convert Firestore documents
  /// to and from [Message] objects.
  late final CollectionReference<Message> _messagesRef;

  /// The stream subscription that listens to Firestore for message updates.
  StreamSubscription<QuerySnapshot<Message>>? _messagesSubscription;

  /// The stream controller that broadcasts the list of messages.
  final _messagesController = StreamController<List<Message>>.broadcast();

  /// A stream of messages from the current match room.
  ///
  /// UI components can listen to this stream to get real-time updates.
  Stream<List<Message>> get messages => _messagesController.stream;

  FirestoreMessageController({required this.instance, required this.roomId}) {
    _messagesRef = instance
        .collection('matches')
        .doc(roomId)
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (snapshot, _) => Message.fromJson(snapshot.data()!),
          toFirestore: (message, _) => message.toJson(),
        );

    // Subscribe to the stream of messages from Firestore.
    _messagesSubscription =
        _messagesRef.orderBy('createdAt').snapshots().listen(
      (snapshot) {
        final messages = snapshot.docs.map((doc) => doc.data()).toList();
        _messagesController.add(messages);
        _log.fine('Received and broadcasted ${messages.length} messages.');
      },
      onError: (error) {
        _log.severe('Error listening to message stream: $error');
        _messagesController.addError(error);
      },
    );

    _log.fine('Initialized for room: $roomId');
  }

  /// Sends a message to the Firestore collection, automatically setting the
  /// creation timestamp on the server.
  Future<void> sendMessage(Message message) async {
    try {
      _log.fine('Sending message: ${message.toJson()}');

      // Convert the Message object to a Map for writing.
      final writeData = message.toJson();

      // Inject the server-side timestamp. When this is read back, the
      // `fromFirestore` converter will correctly turn it into a DateTime.
      writeData['createdAt'] = FieldValue.serverTimestamp();

      // Use a raw collection reference (without a converter) to send the map
      // that includes the FieldValue.
      await instance
          .collection('matches')
          .doc(roomId)
          .collection('messages')
          .add(writeData);
      _log.info('Message sent successfully.');
    } catch (e) {
      _log.severe('Failed to send message: $e');
      // Optionally, rethrow or handle the error as needed.
    }
  }

  /// Cleans up resources and cancels stream subscriptions.
  ///
  /// This should be called when the controller is no longer needed to prevent
  /// memory leaks.
  void dispose() {
    _messagesSubscription?.cancel();
    _messagesController.close();
    _log.fine('Disposed');
  }
}
