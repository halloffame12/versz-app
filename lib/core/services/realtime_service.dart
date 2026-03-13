import 'dart:async';
import 'package:appwrite/appwrite.dart';

class RealtimeService {
  final Client client;
  late final Realtime _realtime;
  RealtimeSubscription? _subscription;
  
  final StreamController<RealtimeMessage> _streamController =
      StreamController<RealtimeMessage>.broadcast();

  RealtimeService(this.client) {
    _realtime = Realtime(client);
  }

  Stream<RealtimeMessage> get stream => _streamController.stream;

  void subscribe(List<String> channels) {
    _subscription?.close();
    _subscription = _realtime.subscribe(channels);
    
    _subscription!.stream.listen((message) {
      _streamController.add(message);
    });
  }

  void subscribeToCollection(String collectionId, Function(Map<String, dynamic>) onMessage) {
    final channel = 'databases.default.collections.$collectionId.documents';
    _subscription?.close();
    _subscription = _realtime.subscribe([channel]);
    
    _subscription!.stream.listen((message) {
      if (message.payload.isNotEmpty) {
        onMessage(message.payload);
      }
    });
  }

  void unsubscribe() {
    _subscription?.close();
    _subscription = null;
  }

  void dispose() {
    unsubscribe();
    _streamController.close();
  }
}
