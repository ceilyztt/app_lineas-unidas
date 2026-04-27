import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _apiUrl = 'https://ve.dolarapi.com/v1/dolares/oficial';

  Future<double> fetchBcvRate() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // La API devuelve el precio oficial en la propiedad 'promedio'
        if (data['promedio'] != null) {
          return (data['promedio'] as num).toDouble();
        }
      }
      return 0.0;
    } catch (e) {
      print('Error obteniendo tasa BCV: $e');
      return 0.0;
    }
  }
}
