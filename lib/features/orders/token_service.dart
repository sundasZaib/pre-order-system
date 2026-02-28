class TokenService {
  TokenService._();

  static final TokenService instance = TokenService._();

  DateTime? _lastDate;
  int _counter = 0;

  String generateDailyToken() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastDate == null || !_isSameDay(_lastDate!, today)) {
      _counter = 0;
      _lastDate = today;
    }

    _counter += 1;
    return _counter.toString().padLeft(3, '0');
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
