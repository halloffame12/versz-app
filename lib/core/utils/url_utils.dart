Uri? parseNetworkUrl(String? rawUrl) {
  if (rawUrl == null) return null;
  final value = rawUrl.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  final hasHttpScheme = uri.scheme == 'http' || uri.scheme == 'https';
  if (!hasHttpScheme || uri.host.isEmpty) return null;
  return uri;
}

bool isValidNetworkUrl(String? rawUrl) => parseNetworkUrl(rawUrl) != null;
