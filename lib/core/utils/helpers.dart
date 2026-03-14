/// Utility helpers for common operations
String formatCount(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1)}M';
  } else if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
  return n.toString();
}

/// Format duration in seconds to MM:SS or H:MM:SS format
String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}

/// Generate debate share URL
String debateShareUrl(String debateId) => 'https://versz.app/debate/$debateId';

/// Generate profile share URL  
String profileShareUrl(String username) => 'https://versz.app/profile/$username';

/// Capitalize first letter of string
String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

/// Parse comma-separated hashtags into list
List<String> parseHashtags(String text) {
  if (text.isEmpty) return [];
  return text
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList();
}

/// Join list of strings with commas
String joinHashtags(List<String> tags) => tags.join(', ');
