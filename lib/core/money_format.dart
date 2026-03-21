/// Kenyan Shilling display for the POS (avoid `$` which reads as USD).
String formatKes(num amount, {int fractionDigits = 2}) {
  return 'Ksh ${amount.toStringAsFixed(fractionDigits)}';
}
