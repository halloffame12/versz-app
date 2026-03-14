import 'package:appwrite/appwrite.dart';
import '../constants/appwrite_constants.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Functions functions;
  late Realtime realtime;

  AppwriteService._internal() {
    const isProduction = bool.fromEnvironment('dart.vm.product');
    client = Client()
      ..setEndpoint(AppwriteConstants.endpoint)
      ..setProject(AppwriteConstants.projectId)
      ..setSelfSigned(status: !isProduction);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    functions = Functions(client);
    realtime = Realtime(client);
  }
}
