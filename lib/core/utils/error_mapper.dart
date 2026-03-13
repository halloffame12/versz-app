import 'package:appwrite/appwrite.dart';
import '../constants/app_strings.dart';

class ErrorMapper {
  static String map(dynamic error) {
    if (error is AppwriteException) {
      switch (error.code) {
        case 401:
          return 'Invalid credentials. Please try again.';
        case 404:
          return 'Resource not found.';
        case 409:
          return 'This user or resource already exists.';
        case 429:
          return 'Too many requests. Please slow down.';
        default:
          return error.message ?? AppStrings.somethingWentWrong;
      }
    }
    
    if (error.toString().contains('SocketException')) {
      return AppStrings.networkError;
    }

    return AppStrings.somethingWentWrong;
  }
}
