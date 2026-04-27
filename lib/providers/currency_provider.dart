import 'package:flutter/foundation.dart';
import '../services/currency_service.dart';

class CurrencyProvider with ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
  
  double _bcvRate = 0.0;
  bool _isLoading = true;

  double get bcvRate => _bcvRate;
  bool get isLoading => _isLoading;

  CurrencyProvider() {
    fetchRate();
  }

  Future<void> fetchRate() async {
    _isLoading = true;
    notifyListeners();

    final rate = await _currencyService.fetchBcvRate();
    if (rate > 0) {
      _bcvRate = rate;
    } else {
      // Si falla, podríamos establecer un valor por defecto o mantener el 0.0 para ocultar el precio en Bs.
      _bcvRate = 0.0; 
    }

    _isLoading = false;
    notifyListeners();
  }
}
