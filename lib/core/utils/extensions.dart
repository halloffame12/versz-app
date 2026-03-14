import 'package:flutter/material.dart';
import 'helpers.dart';

/// String extensions
extension StringExt on String {
  /// Capitalize first letter
  String get capitalized => capitalize(this);

  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;

  /// Abbreviate string to max length with ellipsis
  String abbreviate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - 3)}...';
  }

  /// Remove all whitespace
  String get noWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Add prefix to string
  String withPrefix(String prefix) => '$prefix$this';

  /// Add suffix to string
  String withSuffix(String suffix) => '$this$suffix';

  /// Safe substring that won't throw
  String safeSub(int start, [int? end]) {
    int s = start.clamp(0, length);
    int e = (end ?? length).clamp(0, length);
    if (s > e) return '';
    return substring(s, e);
  }
}

/// DateTime extensions
extension DateTimeExt on DateTime {
  /// Check if same day as another DateTime
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if is today
  bool get isToday => isSameDay(DateTime.now());

  /// Check if is yesterday
  bool get isYesterday {
    return isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Get formatted date like "Mon 10 Mar"
  String formatDate() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[weekday - 1]} $day ${months[month - 1]}';
  }

  /// Get time of day like "2:30 PM"
  String formatTime() {
    final hour = this.hour > 12 ? this.hour - 12 : this.hour;
    final minute = this.minute.toString().padLeft(2, '0');
    final period = this.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Seconds since this timestamp
  int get secondsSince => DateTime.now().difference(this).inSeconds;

  /// Minutes since this timestamp
  int get minutesSince => DateTime.now().difference(this).inMinutes;

  /// Hours since this timestamp
  int get hoursSince => DateTime.now().difference(this).inHours;

  /// Days since this timestamp
  int get daysSince => DateTime.now().difference(this).inDays;
}

/// int extensions
extension IntExt on int {
  /// Format number as count (1K, 1.2M, etc)
  String get formattedCount => formatCount(this);

  /// Format duration in seconds
  String get formattedDuration => formatDuration(this);

  /// Check if is even
  bool get isEven => this % 2 == 0;

  /// Check if is odd
  bool get isOdd => this % 2 != 0;

  /// Clamp between min and max
  int clamp(int min, int max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

/// double extensions
extension DoubleExt on double {
  /// Round to specific decimal places
  double roundTo(int decimals) {
    int fac = pow(10, decimals).toInt();
    return (this * fac).round() / fac;
  }

  /// Check if approximately equal to another double
  bool approxEqual(double other, {double epsilon = 0.001}) {
    return (this - other).abs() < epsilon;
  }

  /// Clamp between min and max
  double clamp(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

/// List extensions
extension ListExt<T> on List<T> {
  /// Get random element
  T? get random => isEmpty ? null : this[(DateTime.now().microsecond % length)];

  /// Check if list contains all items in other list
  bool containsAll(List<T> other) => other.every((item) => contains(item));

  /// Remove duplicates while preserving order
  List<T> get unique {
    final seen = <T>{};
    return where((item) => seen.add(item)).toList();
  }

  /// Chunk list into sublists of size n
  List<List<T>> chunked(int size) {
    if (size <= 0) throw ArgumentError('Size must be positive');
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, (i + size).clamp(0, length).toInt()));
    }
    return chunks;
  }
}

/// Color extensions
extension ColorExt on Color {
  /// Lighten color by factor (0-1)
  Color lighten([double factor = 0.1]) {
    assert(factor >= 0 && factor <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness + factor).clamp(0.0, 1.0)).toColor();
  }

  /// Darken color by factor (0-1)
  Color darken([double factor = 0.1]) {
    assert(factor >= 0 && factor <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0)).toColor();
  }

  /// Get contrasting color (black or white)
  Color get contrastColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Color(0xFF000000) : Color(0xFFFFFFFF);
  }

  /// Convert to hex string
  String toHex() => '#${toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// Add opacity/alpha
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }
}

/// BuildContext extensions
extension BuildContextExt on BuildContext {
  /// Check if dark mode is enabled
  bool get isDark => MediaQuery.platformBrightnessOf(this) == Brightness.dark;

  /// Get screen size
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Get padding
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Get view insets (keyboard height)
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Get device orientation
  Orientation get orientation => MediaQuery.orientationOf(this);

  /// Check if portrait
  bool get isPortrait => orientation == Orientation.portrait;

  /// Check if landscape
  bool get isLandscape => orientation == Orientation.landscape;

  /// Show snackbar convenience method
  void showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }
}

/// Duration extensions
extension DurationExt on Duration {
  /// Format duration as string MM:SS or H:MM:SS
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if duration is positive
  bool get isPositive => inMicroseconds > 0;

  /// Check if duration is zero
  bool get isZero => inMicroseconds == 0;

  /// Check if duration is negative
  bool get isNegative => inMicroseconds < 0;
}

// Helper for pow function
int pow(int base, int exponent) {
  int result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
