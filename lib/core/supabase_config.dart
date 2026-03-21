/// Project URL — must stay in sync with `Supabase.initialize` in `main.dart`.
const String kSupabaseProjectUrl = 'https://eubbmivxtdyvunyblrhd.supabase.co';

/// Edge Function that receives Safaricom STK callbacks (writes `mpesa_callback_results`).
String get kMpesaCallbackEdgeUrl => '$kSupabaseProjectUrl/functions/v1/mpesa-callback';
