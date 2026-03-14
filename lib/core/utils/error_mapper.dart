import 'package:appwrite/appwrite.dart';
import '../constants/app_strings.dart';

class ErrorMapper {
  static String map(dynamic error) {
    if (error is AppwriteException) {
      return authMessageForCode(error.code);
    }
    
    if (error.toString().contains('SocketException')) {
      return AppStrings.networkError;
    }

    return AppStrings.somethingWentWrong;
  }

  static String authMessageForCode(int? code) {
    switch (code) {
      case 400:
        return 'Invalid email address. Please check and try again.';
      case 401:
        return 'Invalid verification code. Please try again.';
      case 404:
        return 'No account found with this email. Please sign up first.';
      case 409:
        return 'An account with this email already exists. Please login instead.';
      case 429:
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return AppStrings.somethingWentWrong;
    }
  }
}
