// Production-safe messages for common failures (network, Supabase auth, etc.).

String userFriendlyAuthOrNetworkError(Object error) {
  final s = error.toString().toLowerCase();

  if (s.contains('failed host lookup') ||
      s.contains('no address associated with hostname') ||
      s.contains('socketexception') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection reset by peer') ||
      s.contains('connection aborted') ||
      (s.contains('clientexception') && (s.contains('socket') || s.contains('failed host'))) ||
      (s.contains('authretryablefetchexception') &&
          (s.contains('socket') || s.contains('failed host') || s.contains('clientexception')))) {
    return 'No internet connection. Check Wi‑Fi or mobile data and try again.';
  }

  if (s.contains('timed out') || s.contains('timeout')) {
    return 'The request took too long. Check your connection and try again.';
  }

  if (s.contains('invalid login credentials')) {
    return 'Incorrect email or password.';
  }
  if (s.contains('email not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (s.contains('user already registered') ||
      s.contains('already been registered') ||
      s.contains('already registered')) {
    return 'This email is already registered.';
  }

  return 'Something went wrong. Please try again.';
}

/// Short message for M-Pesa / Edge Function failures shown in checkout.
String userFriendlyMpesaError(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('failed host lookup') ||
      s.contains('socketexception') ||
      s.contains('network is unreachable') ||
      s.contains('clientexception')) {
    return 'No internet connection. Check your network and try again.';
  }
  if (s.contains('merchant') && s.contains('exist')) {
    return 'M-Pesa could not verify this shop. In Shop Settings, confirm Paybill, Till, Passkey, and Sandbox match your Daraja app.';
  }
  return raw.length > 200 ? '${raw.substring(0, 197)}…' : raw;
}
