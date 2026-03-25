import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_strings.dart';

class GuestService {
  static const int maxGuestQueries = 3;
  
  int _queryCount = 0;
  int get queryCount => _queryCount;

  bool get isLimitReached => _queryCount >= maxGuestQueries;

  void incrementQuery() {
    _queryCount++;
  }

  void reset() {
    _queryCount = 0;
  }
}

final guestServiceProvider = Provider((ref) => GuestService());
