// ignore_for_file: avoid_print
import 'package:dart_appwrite/dart_appwrite.dart';

const String endpoint = 'https://sgp.cloud.appwrite.io/v1';
const String projectId = '69b00336003a3772ee69';
const String apiKey =
    'standard_ee64dfd2e25647031bb0aa81933f4e8abd57ffe92de5f70efb2ef0cf06cf6610f1b6fe0e3a1a78c62c3ade6fa4db38f60b7b2d54bb86723e66763a1a7b0736066af04f1a44c087b4b57d559461b63ecbcf5152babafc95904dac36ddcbe2f2fb0a6e2ac98317ae56f7d0e23b8fe117c2681782c5c5e6ff500ac859fa33542f40';
const String databaseId = 'versz-db';

late Client client;
late Databases databases;

void main() async {
  client = Client()
      .setEndpoint(endpoint)
      .setProject(projectId)
      .setKey(apiKey)
      .setSelfSigned(status: true);

  databases = Databases(client);

  print('═══════════════════════════════════════');
  print('    DELETING VERSZ DATABASE');
  print('═══════════════════════════════════════');
  print('');

  try {
    await databases.delete(databaseId: databaseId);
    print('✅ Database deleted: versz-db');
    print('');
    print('Next step: Run setup_appwrite.dart to recreate');
    print('');
    print('═══════════════════════════════════════');
  } catch (e) {
    print('❌ Error deleting database: $e');
    print('═══════════════════════════════════════');
  }
}
